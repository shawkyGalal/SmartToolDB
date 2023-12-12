# Use the base image
FROM gvenzl/oracle-free

# Install git
RUN apt-get update && apt-get install -y git

WORKDIR /opt/oracle/
# Clone your GitHub repository
RUN git clone https://github.com/shawkyGalal/SmartToolDB.git


# Run setup scripts
# RUN echo "Current directory:" && pwd && \
#    echo "Contents of /opt/oracle/setup-scripts:" && ls -l /opt/oracle/setup-scripts && \
#    echo "Executing chmod command" && \
#    chmod +x /opt/oracle/setup-scripts/*.sql
	
# RUN chmod +x /opt/oracle/setup-scripts/setup.sh
RUN /opt/oracle/setup-scripts/setup.sh
