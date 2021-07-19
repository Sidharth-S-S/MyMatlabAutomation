import glob
import os
import sys

try:

    VersionCheck = ('%d.%d-%s.egg'%(sys.version_info.major,sys.version_info.minor,'win-amd64' if os.name == 'nt' else 'linux-x86_64'))
    
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
import queue

IM_WIDTH = 640
IM_HEIGHT = 480
front_camera = None
collision_hist = []

def get_speed(vehicle):
    velocity = vehicle.get_velocity()
    return 3.6*np.sqrt(velocity.x**2 + velocity.y**2 + velocity.z**2)


def collision_data(event):
        collision_hist.append(event)
        # print(f'The collison Sensor Data is {event}')

def process_img(image):
        i = np.array(image.raw_data)
        #np.save("iout.npy", i)
        i2 = i.reshape((IM_HEIGHT, IM_WIDTH, 4))
        #Only Considering the RGB Sensor Values
        i3 = i2[:, :, :3]
        cv2.imshow("",i3)
        cv2.waitKey(1)
        front_camera = i3


class VehiclePIDController():

    def __init__(self,vehicle,Arg_Lateral,Arg_Longitudinal,max_throttle = 0.8 ,max_brake = 0.3,max_steer = 0.8):
        self.max_brake = max_brake
        self.max_throttle = max_throttle
        self.max_steer = max_steer
        self.vehicle = vehicle
        self.world = vehicle.get_world()
        self.past_steering = self.vehicle.get_control().steer
        self.Long_Control = PIDLongitudinalController(self.vehicle,**Arg_Longitudinal)
        self.Lat_Control  = PIDLateralController(self.vehicle,**Arg_Lateral)


    def run_step(self, target_speed, waypoint):
        acceleration = self.Long_Control.run_step(target_speed)
        current_steering = self.Lat_Control.run_step(waypoint)
        control = carla.VehicleControl()

        if acceleration >= 0.0:
            control.throttle = min(acceleration,self.max_throttle)
            control.brake = 0.0
        else:
            control.throttle = 0.0
            control.brake = min(abs(acceleration),self.max_brake)

        #slowly increasing the steering to avoid an abrupt change 

        if current_steering > self.past_steering + 0.1:
            current_steering = self.past_steering+0.1
        elif current_steering < self.past_steering - 0.1 :
            current_steering = self.past_steering-0.1
        
        # Check if the calculated Steering is exceeding the limit or not
        if current_steering >= 0:
            steering = min(self.max_steer , current_steering)
        else:
            steering = max(-self.max_steer,current_steering)

        self.past_steering = steering
        print(f'At time {time.time()} Steering is : {steering} , Throttle is : {control.throttle} & Brake is : {control.brake}')

        control.steer = steering
        control.handbrake = False
        control.manual_gear_shift = False
        # Gear to be Decided Later 
        # control.gear = 2 / 3 / 4 
        # control.reverse = False
        return control


class PIDLongitudinalController():

    def __init__(self, vehicle, Kp = 1.0 , Kd = 1.0 , Ki = 1.0 , dt = 0.03):
        self.vehicle = vehicle
        self.Kp = Kp
        self.Kd = Kd
        self.Ki = Ki
        self.dt = dt
        self.errorBuffer = queue.deque(maxlen = 10)

    def run_step(self,target_speed):
        current_speed = get_speed(self.vehicle)
        print(f'Current speed = {current_speed}')
        return self.pid_controller(target_speed, current_speed)

    def pid_controller(self,target_speed,current_speed):
        error = target_speed - current_speed
        self.errorBuffer.append(error)

        if len(self.errorBuffer)>=2 : 
            #difference of last errors
            de = (self.errorBuffer[-1] -  self.errorBuffer[-2]) / self.dt
            ie = sum(self.errorBuffer) * self.dt

        else:
            de = 0.0
            ie = 0.0 
        
        #Calculate the value of the Erorr and limit it to   -1 to 1 
        return np.clip( (self.Kp * error) + (self.Kd * de) + (self.Ki * ie), -1.0, 1.0)


class PIDLateralController():

    def __init__(self,vehicle,Kp = 1.0 , Kd = 1.0 , Ki = 1.0 , dt = 0.03):
        self.vehicle = vehicle
        self.Kp = Kp
        self.Kd = Kd
        self.Ki = Ki
        self.dt = dt
        #New Logic for error Buffer
        self.errorBuffer = queue.deque(maxlen = 10)

    def run_step(self,waypoint):
        return self.pid_controller(waypoint,self.vehicle.get_transform())

    def pid_controller(self,waypoint,VehTransform):
        v_begin = VehTransform.location
        v_end = v_begin + carla.Location(x=np.cos(np.radians(VehTransform.rotation.yaw)),
                                         y= np.sin(np.radians(VehTransform.rotation.yaw)))
        
        v_vec = np.array([v_end.x - v_begin.x , v_end.y - v_begin.y, 0.0])
        w_vec = np.array([waypoint.transform.location.x - v_begin.x , 
                          waypoint.transform.location.y - v_begin.y , 
                          0.0])

        # cos_inv(v.w / |w|*|v|)
        dot = np.arccos(np.clip(
            np.dot(w_vec,v_vec) / 
            np.linalg.norm(w_vec)*np.linalg.norm(v_vec),
            -1.0, 1.0))
        cross = np.cross(v_vec,w_vec)

        if cross[2] < 0:
            dot *=  -1.0

        self.errorBuffer.append(dot)

        if len(self.errorBuffer)>=2 : 
            #difference of last errors
            de = (self.errorBuffer[-1] -  self.errorBuffer[-2]) / self.dt
            ie = sum(self.errorBuffer) * self.dt

        else:
            de = 0.0
            ie = 0.0 

        #Calculate the value of the Erorr and limit it to   -1 to 1 
        return np.clip( (self.Kp * dot) + (self.Kd * de) + (self.Ki * ie) , -1.0 , 1.0)

class ControlVehiclePhysics():

    def __init__(self,vehicle):
        self.vehicle = vehicle
        self.physics_control = vehicle.get_physics_control()

    def CreateControl(self):   
        # Create Wheels Physics Control
        front_left_wheel  = carla.WheelPhysicsControl(tire_friction=4.5, damping_rate=1.0, max_steer_angle=70.0, radius=30.0)
        front_right_wheel = carla.WheelPhysicsControl(tire_friction=2.5, damping_rate=1.5, max_steer_angle=70.0, radius=25.0)
        rear_left_wheel   = carla.WheelPhysicsControl(tire_friction=1.0, damping_rate=0.2, max_steer_angle=0.0,  radius=15.0)
        rear_right_wheel  = carla.WheelPhysicsControl(tire_friction=1.5, damping_rate=1.3, max_steer_angle=0.0,  radius=20.0)
        wheels = [front_left_wheel, front_right_wheel, rear_left_wheel, rear_right_wheel]

        self.physics_control.torque_curve = [carla.Vector2D(x=0, y=400), carla.Vector2D(x=1300, y=600)]
        self.physics_control.max_rpm = 10000
        self.physics_control.moi = 1.0
        self.physics_control.damping_rate_full_throttle = 0.0
        self.physics_control.use_gear_autobox = True
        self.physics_control.gear_switch_time = 0.5
        self.physics_control.clutch_strength = 10
        self.physics_control.mass = 10000
        self.physics_control.drag_coefficient = 0.25
        self.physics_control.steering_curve = [carla.Vector2D(x=0, y=1), carla.Vector2D(x=100, y=1), carla.Vector2D(x=300, y=1)]
        self.physics_control.wheels = wheels
        self.physics_control.use_sweep_wheel_collision = True
        
def main():
    actor_list = []
    
    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)
        
        #Load the Town 02 out of the available Maps
        world = client.get_world()
        #Change the Weather (Clear/Cloudy/Wet/WetCloudy/SoftRain/MidRainy/HardRain  Noon/Sunset)
        world.set_weather(carla.WeatherParameters.ClearNoon)

        #Check the Vehicle Library from the blueprint lib
        blueprint_library = world.get_blueprint_library()

        # Destroy all the vehicles present before starting the simulation
        OldActiveActors = world.get_actors().filter('vehicle.*.*')

        for actors in OldActiveActors:
          actors.destroy()

        vehicle_bp = blueprint_library.filter('cybertruck')[0]
        if vehicle_bp.has_attribute('color'):
            vehicle_bp.set_attribute('color', '255,0,0')

        # spawn_points = world.get_map().get_spawn_points()
        # below spawn point is to start and go straight 
        # spawn_point = carla.Transform(carla.Location(x=-85, y= -30.0 , z=10),carla.Rotation(pitch = 0,yaw=90,roll=0))
        spawn_point = carla.Transform(carla.Location(x=-85, y= -20.0 , z=10),carla.Rotation(pitch = 0,yaw=120,roll=0))
        vehicle = world.spawn_actor(vehicle_bp, spawn_point)

        print(f'The vehicle location is {vehicle.get_location()}')
        actor_list.append(vehicle)
        print(f'created the actor {vehicle.type_id} in the environment.')
        print("Ego vehicle center of mass: ", vehicle.bounding_box.location)
        print("Ego vehicle extention: ", vehicle.bounding_box.extent)
        
        #Control Logic to control the Long + Lat Feature
        control_vehicle = VehiclePIDController(vehicle,
        Arg_Lateral={'Kp' : 1.0 , 'Kd' : 0.0 , 'Ki' : 0.0 },
        Arg_Longitudinal={'Kp' : 1.0 , 'Kd' : 0.0 , 'Ki' : 0.0 })

        #Add the Camera sensor for processing 
        camera_bp = blueprint_library.find('sensor.camera.rgb')
        # Modify the attributes of the blueprint to set image resolution and field of view.
        camera_bp.set_attribute('image_size_x',f'{IM_WIDTH}')
        camera_bp.set_attribute('image_size_y',f'{IM_HEIGHT}')
        camera_bp.set_attribute('fov', '110')
        
        #spawn the camera to the vehicle
        sensor_spawn_point = carla.Transform(carla.Location(x=2.0, z=1.25))
        rgb_camerasensor = world.spawn_actor(camera_bp, sensor_spawn_point, attach_to=vehicle)
        actor_list.append(rgb_camerasensor)
        print(f'created {rgb_camerasensor.type_id} in the environment .')
        rgb_camerasensor.listen(lambda data : process_img(data))
        #Add a Collison Sensor to get  all the data 
        colsensor = blueprint_library.find('sensor.other.collision')
        colsensor = world.spawn_actor(colsensor, sensor_spawn_point, attach_to=vehicle)
        actor_list.append(colsensor)
        colsensor.listen(lambda event: collision_data(event))
        print(f'created {colsensor.type_id} in the environment .')

        # # Apply Vehicle Physics Control for the vehicle
        Physics = ControlVehiclePhysics(vehicle)
        Physics.CreateControl()
        print(Physics.physics_control)
        # vehicle.apply_physics_control(Physics.physics_control)       

        while True:
            waypoints = world.get_map().get_waypoint(vehicle.get_location())
            waypoint = np.random.choice(waypoints.next(0.3))
            control_signal = control_vehicle.run_step(5,waypoint)
            vehicle.apply_control(control_signal)

        time.sleep(15)

    except KeyboardInterrupt:
        print('\nExit by user.')

    finally:
        print('destroying actors')
        client.apply_batch([carla.command.DestroyActor(x) for x in actor_list])
        print('done.')

if __name__ == '__main__':

    main()
