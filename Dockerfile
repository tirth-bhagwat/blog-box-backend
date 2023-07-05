
FROM ubuntu:22.04

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl

# Install flow cli
RUN sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"

# Add flow to path
ENV PATH="/root/.local/bin:${PATH}"

# Create entrypoint.sh file
RUN echo "#!/bin/bash" > /entrypoint.sh
RUN echo "/root/.local/bin/flow emulator --persist > output.log" >> /entrypoint.sh
# # if persist = true
# RUN echo "if [ \"$PERSIST\" = \"true\" ]; then" >> /entrypoint.sh
# # else
# RUN echo "else" >> /entrypoint.sh
# RUN echo "/root/.local/bin/flow emulator > output.log" >> /entrypoint.sh
# RUN echo "fi" >> /entrypoint.sh

# Make entrypoint.sh executable
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT [ "bash", "/entrypoint.sh" ]

