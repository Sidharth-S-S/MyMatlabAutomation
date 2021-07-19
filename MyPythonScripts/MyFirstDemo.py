import glob
import os
import sys

try:

    VersionCheck = ('%d.%d-%s.egg'%(sys.version_info.major,sys.version_info.minor,'win-amd64' if os.name == 'nt' else 'linux-x86_64'));
    
    if any(SysPath.find(VersionCheck)!=-1 for SysPath in sys.path)==False :
        sys.path.append(glob.glob('../carla/dist/carla-*%d.%d-%s.egg' % (
            sys.version_info.major,
            sys.version_info.minor,
            'win-amd64' if os.name == 'nt' else 'linux-x86_64'))[0])
    
except IndexError:
    pass

import carla
import random
import time
import numpy as np
import cv2

IM_WIDTH = 640
IM_HEIGHT = 480 

def ImgProcessing(Image):
    #print(dir(Image))
    #Raw data would give me the array elements we got from the Camera Sensor for Processing.
    image_data = np.array(Image.raw_data)
    print(image_data.shape)
    #print(image_data.shape)  to reshape now i would need to Height * Width * RGBA (CARLA Default)
    image_data2 = image_data.reshape(IM_HEIGHT,IM_WIDTH,4)
    image_data_rgb = image_data2[:,:,:3] #Only considering the RGB Values 
    #opencv now for the image processing now
    cv2.imshow("",image_data_rgb)
    cv2.waitKey(1)
    return image_data_rgb/255

def get_absvalues(data3D):
        return abs(np.sqrt(data3D.x**2 + data3D.y**2 + data3D.z**2))

class GetCurrentData():

    def __init__(self,vehicle):
        self.velocity           = get_absvalues(vehicle.get_velocity())
        self.acceleration       = get_absvalues(vehicle.get_acceleration())
        self.angularVelocity    = get_absvalues(vehicle.get_angular_velocity())

def main():
    actor_list = []
    
    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)

        world = client.get_world()
        print('The available Maps are ',client.get_available_maps(),end='\n')
        world = client.load_world('Town05')
        world.set_weather(carla.WeatherParameters.WetCloudyNoon)
        print('After Setting the Environemnt by Enum the weather is \n',world.get_weather(),end = '\n \n')

        #Check the Vehicle Library from the blueprint lib
        blueprint_library = world.get_blueprint_library()
        vehicle_bp_1 = blueprint_library.filter('etron')
        vehicle_bp_2 = blueprint_library.filter('cybertruck')
        print('The Selected Vehicle is : ',vehicle_bp_1[0],'and \n',vehicle_bp_2[0])

        spawn_points = world.get_map().get_spawn_points()
        print('The Number of available spawn points are in the map are : ',len(spawn_points),end = '\n')

        #Selecting the Point Randomly  & by location
        spawn_point_1 = random.choice(world.get_map().get_spawn_points())
        spawn_point_2 = carla.Transform(carla.Location(x=130, y=200, z=20),carla.Rotation(yaw=180))
        # spawn_point_2 = carla.Transform(carla.Location(x=75, y= -1.0 , z=15),carla.Rotation(yaw=0,pitch = 0))
        

        vehicle1 = world.spawn_actor(vehicle_bp_1[0], spawn_point_1)
        vehicle2 = world.spawn_actor(vehicle_bp_2[0], spawn_point_2)

        actor_list.append(vehicle1)
        actor_list.append(vehicle2)
        print('created the actor ',vehicle1.type_id,' to drive in AutoPilot & ',vehicle2.type_id, 'to drive in Control Logic.')
        vehicle1.set_autopilot(True)

        #Printing the location of both the Ego Vehicle 
        print('The Vehicle 1 is in Location : ',vehicle1.get_location(),'\n Vehicle 2 is in Location : ',vehicle2.get_location() ,'before changing the location.',end = '\n')
        Prev_location = vehicle2.get_location()
        Prev_location += carla.Location(x=20, y=-5)
        vehicle2.set_location(Prev_location)
        time.sleep(0.5)
        print('Moved vehicle to ', vehicle2.get_location())

        '''
        Add a Camera Sensor to the Vehicle so that it would record the Photos at a specific Sensor tick duration.
        The image resultion is defined as Constant and it would egenrate 640 * 480 mp with a FOV of  110 degree. 
        The Camera is attached to the Vehicle so that it would move along with the Vehicle .
        '''

        cam_bp = blueprint_library.find("sensor.camera.rgb")
        cam_bp.set_attribute('image_size_x',f'{IM_WIDTH}')
        cam_bp.set_attribute('image_size_y',f'{IM_HEIGHT}')
        cam_bp.set_attribute('fov', '110')

        # Set the time in seconds between sensor captures 
        cam_bp.set_attribute('sensor_tick', '0.5')
        
        #spawn the camera to the vehicle
        camera_spawn_point = carla.Transform(carla.Location(x=3.0, z=2.25))
        sensor = world.spawn_actor(cam_bp, camera_spawn_point, attach_to=vehicle2)
        actor_list.append(sensor)
        print('created %s' % sensor.type_id)

        cc = carla.ColorConverter.LogarithmicDepth #CityScapesPalette
        sensor.listen(lambda image: image.save_to_disk('_out/%06d.png' % image.frame, cc))
        # sensor.listen(lambda data : ImgProcessing(data))

        # Applying the Vehicle Control to the Ego Vehicle
        print('Starting the Vehicle Control by Throttle Brake Steer')
        CurrVehData = GetCurrentData(vehicle2)
        print('Before Control Vehicle Data are : \n',
        'Velocity :',CurrVehData.velocity,
        '\t Acceleration : ',CurrVehData.acceleration,
        '\t Angular Velocity : ',CurrVehData.angularVelocity,end='\n')
        vehicle2.apply_control(carla.VehicleControl(throttle=0.8))
        time.sleep(5)

        CurrVehData = GetCurrentData(vehicle2)
        print('After 1st Control Vehicle Data are : \n',
        'Velocity :',CurrVehData.velocity,
        '\t Acceleration : ',CurrVehData.acceleration,
        '\t Angular Velocity : ',CurrVehData.angularVelocity,end='\n')
        vehicle2.apply_control(carla.VehicleControl(throttle=0.75, steer=-1.0))
        #Steer -1 means left
        time.sleep(2.5)
        
        CurrVehData = GetCurrentData(vehicle2)
        print('After 2nd Control Vehicle Data are : \n',
        'Velocity :',CurrVehData.velocity,
        '\t Acceleration : ',CurrVehData.acceleration,
        '\t Angular Velocity : ',CurrVehData.angularVelocity,end='\n')
        vehicle2.apply_control(carla.VehicleControl(throttle=0.50, steer=1.0,reverse=True))
        time.sleep(2.5)

        CurrVehData = GetCurrentData(vehicle2)
        print('After 3rd Control Vehicle Data are : \n',
        'Velocity :',CurrVehData.velocity,
        '\t Acceleration : ',CurrVehData.acceleration,
        '\t Angular Velocity : ',CurrVehData.angularVelocity,end='\n')
        vehicle2.apply_control(carla.VehicleControl(throttle=0.0, steer=0.0 , brake = 1.0 ,hand_brake =True,reverse=False))
        time.sleep(0.5)

        CurrVehData = GetCurrentData(vehicle2)
        print('Finally Vehicle Data are : \n',
        'Velocity :',CurrVehData.velocity,
        '\t Acceleration : ',CurrVehData.acceleration,
        '\t Angular Velocity : ',CurrVehData.angularVelocity,end='\n')
        print('\n \n Done Control \n')

        # #Add the Other npc at some other position based on the available spawning points
        for i in range(4):
            spawn_point_2.location.x += 10 
            spawn_point_2.location.y -= 3
            if i % 2 == 0 :
                veh_bp = random.choice(blueprint_library.filter('vehicle.*.*'))
                npc = world.try_spawn_actor(veh_bp,spawn_point_2)
                if npc is not None:
                    actor_list.append(npc)
                    npc.set_autopilot(True)
                    print('Created %s'%npc.type_id)
            else:
                walker_bp = random.choice(blueprint_library.filter('walker.*.*'))
                walker_speed = walker_bp.get_attribute('speed').recommended_values[1]
                walker_bp.set_attribute('speed',walker_speed)

                if walker_bp.has_attribute('is_invincible'):
                    walker_bp.set_attribute('is_invincible', 'false')

                npc = world.try_spawn_actor(walker_bp,spawn_point_2)
                if npc is not None:
                    actor_list.append(npc)
                    print('Created %s'%npc.type_id)

        print('\n Actors are \n',actor_list,end='\n')

        vehicle2.apply_control(carla.VehicleControl(throttle=0.25, steer=-1.0,brake=0.0,hand_brake = False))
        time.sleep(2.5)
        vehicle2.apply_control(carla.VehicleControl(throttle=0.0, steer=0.0,brake=1.0))
        time.sleep(20)

    finally:

        print('destroying actors')
        client.apply_batch([carla.command.DestroyActor(x) for x in actor_list])
        # for actor in actor_list:
        #     actor.destroy()
        print('done.')

if __name__ == '__main__':

    main()
