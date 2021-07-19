#!/usr/bin/env python

# Copyright (c) 2019 Computer Vision Center (CVC) at the Universitat Autonoma de
# Barcelona (UAB).
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

import glob
import os
import sys
import numpy as np
import cv2

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

IM_WIDTH = 640
IM_HEIGHT = 480 

def ImgProcessing(Image):
    print(dir(Image))
    #Raw data would give me the array elements we got from the Camera Sensor for Processing.
    image_data = np.array(Image.raw_data)
    #print(i.shape)  to reshape now i would need to Height * Width * RGBA (CARLA Default)
    image_data2 = image_data.reshape(IM_HEIGHT,IM_WIDTH,4)
    image_data_rgb = image_data2[:,:,:3] #Only considering the RGB Values 
    #opencv now for the image processing now
    cv2.imshow("",image_data_rgb)
    cv2.waitKey(1)
    return image_data_rgb/255


def main():
    actor_list = []
    
    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)
        
        #Load the Town 02 out of the available Maps
        world = client.get_world()
        print('The available Maps are ',client.get_available_maps(),end='\n')
        world = client.load_world('Town02')

        #Change the Weather (Clear/Cloudy/Wet/WetCloudy/SoftRain/MidRainy/HardRain  Noon/Sunset)
        world.set_weather(carla.WeatherParameters.WetCloudyNoon)
        print('After Setting the Environemnt by Enum the weather is \n',world.get_weather(),end = '\n \n')

        #Check the Vehicle Library from the blueprint lib
        blueprint_library = world.get_blueprint_library()

        # Choose a vehicle blueprint at random.
        # vehicle_bp = random.choice(blueprint_library.filter('vehicle.*.*'))
        # vehicle_bp = blueprint_library.filter('etron')
        vehicle_bp = blueprint_library.filter('tesla.model3')
        print('The Selected Vehicle is : %s' % vehicle_bp,end='\n')

        spawn_points = world.get_map().get_spawn_points()
        print('The Number of available spawn points are ',len(spawn_points),end = '\n')

        #Selecting the Point Randomly  
        spawn_point = random.choice(spawn_points)
        #spawn_point = carla.Transform(carla.Location(x=130, y=195, z=40))
        
        vehicle = world.spawn_actor(vehicle_bp, spawn_point)

        actor_list.append(vehicle)
        print('created the actor %s' % vehicle.type_id)
        vehicle.set_autopilot(True)

        #printing the location of the Ego Vehicle 
        Prev_location = vehicle.get_location()
        print('The Vehicle is in Location : ',Prev_location,' before changing the location.',end = '\n')
        Prev_location.x +=20
        vehicle.set_location(Prev_location)
        print('moved vehicle to %s' % Prev_location)

        #Get the Data of the Ego Vehicle with a gap of 1second
        for i in range(10):
            print(' Acceleration is : ',vehicle.get_acceleration(),'\n Angular Velocity is : ',vehicle.get_angular_velocity(),
                  '\n Transform is : ',vehicle.get_transform(),
                  '\n Velocity is : ',vehicle.get_velocity())

            CurrentVelcoity = vehicle.get_velocity()
            CurrentVelcoity.x += 1.0 
            CurrentVelcoity.y += 0.25
            vehicle.set_velocity(CurrentVelcoity)
            print('Current Velocity After changing is - ',CurrentVelcoity)
            time.sleep(1)

        # spawn_point.location += carla.Location(x=10,y=5.0)
        # spawn_point.yaw = -180.0
        
        # #Add the Other npc at some other position based on the available spawning points
        for i in range(len(spawn_points)-1):
            spawn_point.location.x += 10 

            if i % 2 == 0 :
                bp = random.choice(blueprint_library.filter('vehicle.*.*'))
            else:
                bp = random.choice(blueprint_library.filter('walker.*.*'))

            npc = world.try_spawn_actor(bp,spawn_point)
            if npc is not None:
                actor_list.append(npc)
                npc.set_autopilor(True)
                print('Created %s'%npc.type_id)
        
        cam_bp = blueprint_library.find("sensor.camera.rgb")
        #modify the image resolution & fov
        print('The image resolution is : ',cam_bp.get_attribute('image_size_x'),
        cam_bp.get_attribute('image_size_y'),cam_bp.get_attribute('fov'))

        # Modify the attributes of the blueprint to set image resolution and field of view.
        cam_bp.set_attribute('image_size_x',f'{IM_WIDTH}')
        cam_bp.set_attribute('image_size_y',f'{IM_HEIGHT}')
        cam_bp.set_attribute('fov', '110')

        # Set the time in seconds between sensor captures 
        cam_bp.set_attribute('sensor_tick', '1.0')
        
        #spawn the camera to the vehicle
        camera_spawn_point = carla.Transform(carla.Location(x=2.0, z=1.25))
        sensor = world.spawn_actor(cam_bp, camera_spawn_point, attach_to=vehicle)
        actor_list.append(sensor)
        print('created %s' % sensor.type_id)

        # do_something() will be called each time a new image is generated by the camera.
        # sensor.listen(lambda data: do_something(data))
        # sensor.listen(lambda data : ImgProcessing(data))
        cc = carla.ColorConverter.LogarithmicDepth
        sensor.listen(lambda image: image.save_to_disk('_out/%06d.png' % image.frame, cc))


        '''
        command.ApplyAngularImpulse(actor,impulse)
        command.ApplyForce(actor,force)
        command.ApplyImpulse(actor,impulse(N*s))
        command.ApplyTargetAngularVelocity(actor,angular_velocity(deg/s))
        command.ApplyTargetVelocity(actor,velocity(m/s))
        command.ApplyTorque(actor,torque)
        command.ApplyTransform(actor,transform)
        command.ApplyVehicleControl(actor,control (carla.VehicleControl))
        command.ApplyWalkerControl(actor,control (carla.WalkerControl))
        command.ApplyWalkerState(actor,transform (carla.Transform),speed (float – m/s))
        command.SetAutopilot(actor,enabled , port=8000)
        command.SpawnActor(blueprint (carla.ActorBlueprint) , transform (carla.Transform) , parent (carla.Actor))
        '''

        '''
        throttle(0.0 - 1.0) / steer(0.0 - 1.0) / brake(0.0 - 1.0) 
        hand_brake (bool)   / reverse (bool)   / manual_gear_shift (bool) / gear (int)
        '''
        # vehicle.apply_control(carla.VehicleControl(throttle=1.0,steer=0.0))

        '''
        torque_curve (list) Curve measuring Trq in Nm for specific RPM / max_rpm (float) The maximum RPM 
        moi [Moment of Inertia-kg.m2] /use_gear_autobox (True for Automatic Transmission) / gear_switch_time (seconds)
        final_ratio (Fixed Ratio of transmission to wheels) / forward_gears (List of objects defining Vehicle's Gears) 
        mass (kg)float / center_of_mass [m] / steering_curve (Curve that indicates the max steering for a specific forward Speed) 
        '''

        ##############################################################################################################################
        # vehicle.VehiclePhysicsControl(torque_curve=[[0.0,500.0],[5000.0,500.0]] , max_rpm = 5000.0 , moi=1.0 , 
        #                       use_gear_autobox=True, gear_switch_time=0.5,final_ratio=4.0, forward_gears=list(), 
        #                       mass=1000.0, center_of_mass=[0.0, 0.0, 0.0], steering_curve=[[0.0, 1.0], [10.0, 0.5]], wheels=list())
        ##############################################################################################################################

        time.sleep(15)

    finally:

        print('destroying actors')
        # client.apply_batch([carla.command.DestroyActor(x) for x in actor_list])
        for actor in actor_list:
            actor.destroy()
        print('done.')

if __name__ == '__main__':

    main()
