# Lacrosse Seedgen Runner
# LLM-powered seed generation with model rotation

FROM lacrosse-seedgen-base:latest

# Install libCRS
COPY --from=libcrs . /libCRS
RUN /libCRS/install.sh

# Copy entrypoint script
COPY oss-crs/bin/seedgen.sh /crs/oss-crs/bin/seedgen.sh
RUN chmod +x /crs/oss-crs/bin/seedgen.sh

ENTRYPOINT ["/crs/oss-crs/bin/seedgen.sh"]
