#!/usr/bin/env python

# Copyright (c) 2019 Computer Vision Center (CVC) at the Universitat Autonoma de
# Barcelona (UAB).
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

"""Trying Out CARLA For MPC Controller"""

import glob
import os
import sys

try:

    VersionCheck = ('%d.%d-%s.egg' % (sys.version_info.major, sys.version_info.minor,
                    'win-amd64' if os.name == 'nt' else 'linux-x86_64'))

    if any(SysPath.find(VersionCheck) != -1 for SysPath in sys.path) == False:
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
import torch.tensor as tf


from agents.tools.misc import is_within_distance_ahead, is_within_distance, compute_distance

import argparse

# Create the parser
my_parser = argparse.ArgumentParser(description=__doc__)
my_parser.add_argument('--filterveh')
my_parser.add_argument(
    '--sync',
    action='store_true',
    help='Synchronous mode execution')
args = my_parser.parse_args()
# args.world//args.synchronous_mode//args.save_to_disk(camera)


class LaneEstimator(object):

    def __init__(self, camera_info, camera_actor, poly_order, save_to_disk=False):
        # Camera characteristics
        self._camera_info = camera_info
        pose = camera_actor.get_transform()
        self._H = float(pose.location.z)  # Height
        self._pitch = np.radians(float(pose.rotation.pitch))  # Pitch angle
        # Horizontal field of view
        self._h_fov = np.radians(float(camera_info.get_attribute('fov')))
        # Horizontal image size
        self._V = int(camera_info.get_attribute('image_size_x'))
        # Vertical image size
        self._U = int(camera_info.get_attribute('image_size_y'))

        # Vertical field of view (derived from other camera info)
        self._v_fov = 2*np.atan(float(self._U / self._V)
                                * np.tan(self._h_fov / 2))
        # Camera tilt angle (derived)
        self._tilt = np.pi / 2 + self._pitch - self._v_fov / 2
        self.__str__()  # print camera characteristics

        # rectangle of the image to be considered, upper-left and lower-right points
        self.box = (280, 130, 510, 750)
        # Width and height values choosen to crop the image to improve efficiency
        self._width_crop = self.box[3] - self.box[1]
        self._height_crop = self.box[2] - self.box[0]
        # These source-points have been found to be optimal for the camera
        # pose and parameters we're dealing with. This resulted in a better
        # top-view transform than the set of functions reported in the section
        # named "Top-view transform"
        self._source_points = np.array([[150, 0],
                                        [self._width_crop - 300 - 1, 0],
                                        [500, self._height_crop - 1],
                                        [300, self._height_crop - 1]],
                                       dtype="float32")

        # Order of the polynomial fitting (the default value is 2)
        self.n = poly_order
        # Stride and skip values are used to identify lane lines pixels on the
        # top-view image in function compute_poly_params
        self.stride = 2
        self.skip = 5
        self.l = np.empty(6)
        # Kernel of the filter adopted to sharpen the image
        self.kernel = np.array([[-1, -1, -1],
                                [-1, 9, -1],
                                [-1, -1, -1]])
        self.save_to_disk = save_to_disk

    def _detect_lanes(self, image):
        # Addressed in "Lane line feature extraction with CARLA" section

    def process(self, image):
        sharp_image = self._detect_lanes(image)
        warped_image = four_point_transform(sharp_image, self._source_points)
        if self.save_to_disk:
            imageio.imwrite('top_view/lanes.png', warped_image)
        return warped_image
        
    def __str__(self):
        print('*' * 60)
        print("%s %s %s created and positioned" % (self._camera_info.tags[0],
                                                self._camera_info.tags[1], self._camera_info.tags[2]))
        print("-----PARAMETERS-----")
        print("Height: %.2f" % self._H)
        print("Pitch angle: %.2f" % degrees(self._pitch))
        print("Tilt angle: %.2f" % degrees(self._tilt))
        print("Image size: %d x %d" % (self._V, self._U))
        print("Horizontal field of view: ", round_up(degrees(self._h_fov)))
        print("Vertical field of view: ", round_up(degrees(self._v_fov)))
        print('*' * 60)


def main(args):
    actor_list = []

    try:
        client = carla.Client('localhost', 2000)
        client.set_timeout(10.0)

        # Load the specific world passed as input
        client.load_world(args.world)
        print(args.world + " loaded")
        # Retrieve the world and the settings to activate synchronous mode
        world = client.get_world()
        settings = world.get_settings()
        settings.synchronous_mode = args.synchronous_mode
        world.apply_settings(settings)
        if settings.synchronous_mode:
            print("Activating synchronous mode")
        # Get the spectator information to set its 3D pose to observe the ego car
        # behaviour
        spectator = world.get_spectator()
        mymap = world.get_map()
        # Change the Weather (Clear/Cloudy/Wet/WetCloudy/SoftRain/MidRainy/HardRain  Noon/Sunset)
        world.set_weather(carla.WeatherParameters.ClearNoon)

        # Check the Vehicle Library from the blueprint lib
        blueprint_library = world.get_blueprint_library()
        # Destroy all the vehicles present before starting the simulation
        OldActiveActors = world.get_actors().filter('vehicle.*.*')

        for actor in OldActiveActors:
            actor.destroy()

        world.tick()
        world.wait_for_tick()

        # spawn the Vehicle
        vehicle_bp = blueprint_library.filter('cybertruck')[0]
        if vehicle_bp.has_attribute('color'):
            vehicle_bp.set_attribute('color', '255,0,0')

        spawn_point = carla.Transform(carla.Location(x=-85, y=-20.0, z=10),
                                      carla.Rotation(pitch=0, yaw=120, roll=0))
        vehicle = world.spawn_actor(vehicle_bp, spawn_point)
        world.tick()
        world.wait_for_tick()
        # Set spectator pose
        spawn_point.location.z += 30
        spawn_point.rotation.pitch = -60
        spectator.set_transform(spawn_point)
        world.tick()
        world.wait_for_tick()
        print(vehicle.get_location())
        print("%s %s %s created and positioned" % (vehicle_bp.tags[0],
                                                   vehicle_bp.tags[1],
                                                   vehicle_bp.tags[2]))
        actor_list.append(vehicle)
        print("Ego vehicle center of mass: ", vehicle.bounding_box.location)
        print("Ego vehicle extention: ", vehicle.bounding_box.extent)

        cam_blueprint = blueprint_library.find(
            'sensor.camera.semantic_segmentation')
        cam_blueprint.set_attribute('image_size_x', '800')
        cam_blueprint.set_attribute('image_size_y', '600')
        cam_blueprint.set_attribute('fov', '110')
        cam_blueprint.set_attribute('sensor_tick', '0.1')
        transform = carla.Transform(carla.Location(x=1.1, z=1.4),
                                    carla.Rotation(pitch=-5.0))
        semantic_cam = world.spawn_actor(
            cam_blueprint, transform, attach_to=vehicle)
        world.tick()
        world.wait_for_tick()
        print(semantic_cam.get_location())
        actor_list.append(semantic_cam)

        # Istantiate a LaneKeepingAlgorithm object
        mpc_algorithm = LaneKeepingAlgorithm(vehicle, cam_blueprint,
                                             semantic_cam, 2, args.save_to_disk)

        image_queue = queue.Queue()
        semantic_cam.listen(image_queue.put)
        world.tick()
        world.wait_for_tick()
        frame = None

        while True:
            # Get vehicle location and its nearest waypoint
            ego_location = vehicle.get_location()
            vechicle_waypoint = mymap.get_waypoint(ego_location)
            # To have perfect synchronization, the frame number of the image has to be
            # equal to the frame count of the tick
            world.tick()
            ts = world.wait_for_tick()
            if frame is not None:
                if ts.frame_count != frame + 1:
                    logging.warning('frame skip!')

            frame = ts.frame_count

            # It checks if the image frame number from the queue is equal to the
            # tick frame number end exits from the loop only in this case
            while True:
                image = image_queue.get()
                if image.frame_number == ts.frame_count:
                    break
                logging.warning(
                    'wrong image time-stampstamp: frame=%d, image.frame=%d',
                    ts.frame_count,
                    image.frame_number)

            lane_width = vechicle_waypoint.lane_width
            right_lane_waypoint = vechicle_waypoint.get_right_lane()

            if right_lane_waypoint:
                # It computes the vehicle lane level localization and lane curvature needed
                # by the controller with the get_params method of the LaneKeepingAlgorithm
                curvature, lateral_error, yaw_error = mpc_algorithm.get_params(image,
                                                                               lane_width)
                # Other way to compute lateral and yaw error, by using carla.Waypoint class
                e1 = np.sqrt((right_lane_waypoint.transform.location.x - ego_location.x)**2 +
                             (right_lane_waypoint.transform.location.y - ego_location.y)**2) - lane_width/2

                e2 = np.radians(
                    right_lane_waypoint.transform.rotation.yaw - vehicle.get_transform().rotation.yaw)
                print("e1= %.2f, e2= %.2f" % (e1, e2))
                v = vehicle.get_velocity().x

                steer, throttle, brake = mpc_algorithm.get_control_inputs(
                    curvature, e1, e2, v)
            else:
                steer = 0.0
                throttle = 0.4
                brake = 0.0

            print("INPUTS: steer={0:.3f} throttle={1:.3f} brake={2:.3f}".format(
                steer, throttle, brake))
            # Apply control values to the ego vehicle
            vehicle.apply_control(carla.VehicleControl(
                steer=steer, throttle=throttle, brake=brake))

    except KeyboardInterrupt:
        print('\nExit by user.')

    finally:
        if args.synchronous_mode:
            print('Disabling synchronous mode.')
            settings = world.get_settings()
            settings.synchronous_mode = False
            world.apply_settings(settings)

        print('destroying actors')
        client.apply_batch([carla.command.DestroyActor(x) for x in actor_list])
        print('done.')


if __name__ == '__main__':

    main()
