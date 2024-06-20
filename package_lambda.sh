#!/bin/bash

# Create a directory for the package
mkdir -p package

# Install dependencies in the package directory
pip install -r requirements.txt -t package

# Copy the Lambda function code into the package directory
cp lambda_function.py package/

# Create a ZIP file of the package
cd package
zip -r ../lambda_image_conversion.zip .
cd ..

# Clean up the package directory
rm -rf package
