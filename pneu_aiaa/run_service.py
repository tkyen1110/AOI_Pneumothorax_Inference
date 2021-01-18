#!/usr/bin/python3
import os
import yaml, json
import boto3
import requests
# from flask import Flask, request
# from flask import render_template
# from flask import jsonify
from sanic import Sanic
from sanic import response

# app = Flask(__name__)
app = Sanic(__name__)

from botocore.utils import is_valid_endpoint_url
from botocore.client import Config
from botocore.exceptions import ClientError, EndpointConnectionError

docker_data_dir = '/tmp/data/'
docker_dicom_dir = '/tmp/data/dicom'
config_file = '/tmp/data/config/config.yaml'

def download_s3_file(endpoint, access_key, secret_key, bucket, dicom_filepath, dicom_file):
    config = Config(signature_version='s3')
    is_verify = False
    connection = boto3.client(
        's3',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        endpoint_url=endpoint,
        config=config,
        verify=is_verify
    )
    docker_dicom_filepath = os.path.join(docker_dicom_dir, dicom_file)

    try:
        connection.download_file(bucket, dicom_filepath, docker_dicom_filepath)
    except ClientError as e:
        pass

    if os.path.isfile(docker_dicom_filepath):
        return True
    else:
        return False

empty_response = {  "version": "",
                    "flags": {},
                    "shapes": [],
                    "lineColor": [],
                    "fillColor": [],
                    "imagePath": "",
                    "imageData": "",
                    "imageHeight": 0,
                    "imageWidth": 0,
                    "message": ""
                 }

# curl -X POST http://localhost:81/pneu --header "Content-Type: application/json" --data '{"endpoint" : "http://61.219.26.12:8080", "access_key" : "327abedcf2d64324b9a82fc65b4cf265", "secret_key" : "DCWHm9t2Vak3eXPCw0ZPtM0cgfVioyIK5", "bucket" : "pneu-dicom", "file" : "0001-PNEUMO2013021401.dcm"}'
@app.route("/pneu", methods=['POST'])
async def pneu_inference(request):
    request_dict = request.json
    endpoint = request_dict.get('endpoint', None)
    access_key = request_dict.get('access_key', None)
    secret_key = request_dict.get('secret_key', None)
    bucket = request_dict.get('bucket', None)
    dicom_filepath = request_dict.get('file', None)

    # Download file from S3 blob
    if endpoint and access_key and secret_key and bucket and dicom_filepath:
        dicom_file = dicom_filepath.split('/')[-1]
        if not download_s3_file(endpoint, access_key, secret_key, bucket, dicom_filepath, dicom_file):
            empty_response["message"] = "The file does not download from S3 blob"
            return response.json(empty_response)
    else:
        empty_response["message"] = "The API request information is not complete"
        return response.json(empty_response)

    # Query pneumothorax inference API
    pneu_headers = {'Content-Type': 'application/json'}
    pneu_data = {"dcm": dicom_file}
    try:
        r = requests.post('http://localhost:5050/ADV_pneu', headers = pneu_headers, json = pneu_data)
    except requests.exceptions.RequestException as e:
        empty_response["message"] = "Pneumothorax inference API does not exist"
        return response.json(empty_response)

    if r.status_code == requests.codes.ok:
        response_dict = r.json()
        signal = response_dict.get('signal', None)
        errcode = response_dict.get('errcode', None)
        errmessage = response_dict.get('errmessage', None)
        host_heatmap_json_path = response_dict.get('heatmap_json_path', None)

        if host_heatmap_json_path:
            if os.path.isfile(config_file):
                with open(config_file) as file:
                    config_dict = yaml.load(file, Loader=yaml.FullLoader)
                    if config_dict==None:
                        config_dict = {}
            else:
                config_dict = {}

            path = config_dict.get('PATH', None)
            docker_heatmap_json_path = host_heatmap_json_path.replace(path, docker_data_dir)
            json_dict = json.load(open(docker_heatmap_json_path))
            for i in range(len(json_dict["shapes"])):
                json_dict["shapes"][i]["label"] = "pneumothorax_seg"
            return response.json(json_dict)
        else:
            empty_response["message"] = "No AIAA json file is created"
            if signal == "0":
                empty_response["message"] = empty_response["message"] + " due to no pneumothorax"
            elif errmessage:
                empty_response["message"] = empty_response["message"] + " due to " + errmessage
            return response.json(empty_response)
    else:
        empty_response["message"] = "Pneumothorax inference error ({})".format(r.status_code)
        return response.json(empty_response)

@app.route("/label", methods=['POST', 'GET'])
async def get_label(request):
    return response.text("pneumothorax_seg")


if __name__ == "__main__":
    app.run(host = '0.0.0.0', port = 5000)
