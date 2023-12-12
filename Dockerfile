# Use the base image
FROM gvenzl/oracle-free

USER root

# Install necessary tools
RUN microdnf install -y git

USER oracle


WORKDIR /opt/oracle/
# Clone your GitHub repository
RUN git clone https://github.com/shawkyGalal/SmartToolDB.git

	

