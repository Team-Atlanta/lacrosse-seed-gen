# Lacrosse Seedgen LibFuzzer Builder
# Compiles target with libfuzzer+ASan instrumentation

ARG target_base_image
FROM ${target_base_image}

# Install libCRS
COPY --from=libcrs . /libCRS
RUN /libCRS/install.sh

# Copy build script
COPY oss-crs/bin/builder-libfuzzer.sh /builder-libfuzzer.sh
RUN chmod +x /builder-libfuzzer.sh

CMD ["/builder-libfuzzer.sh"]
