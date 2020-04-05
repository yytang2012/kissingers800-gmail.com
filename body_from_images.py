import os
import cv2

from openpose import pyopenpose as op

from settings import IMAGES_DIR
from utils import get_files


def main(image_dir):
    window_name = 'Visualization'
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    all_image_path = get_files(image_dir, file_extension='.jpg$.jpeg$.png')
    all_image_path.sort(key=lambda file_path: file_path.split(os.path.sep)[-1])

    params = dict()
    params["model_folder"] = "/openpose/models/"
    # params["face"] = True
    # params["hand"] = True

    # Starting OpenPose
    opWrapper = op.WrapperPython()
    opWrapper.configure(params)
    opWrapper.start()

    for image_path in all_image_path:
        # Process Image
        datum = op.Datum()

        frame = cv2.imread(image_path)
        datum.cvInputData = frame
        opWrapper.emplaceAndPop([datum])

        output_frame = datum.cvOutputData
        cv2.imshow(window_name, output_frame)
        print("Body keypoints: \n" + str(datum.poseKeypoints))

        key = cv2.waitKey(0) & 0xFF
        if key == ord('q'):
            break


if __name__ == '__main__':
    image_dir = IMAGES_DIR
    main(image_dir)
