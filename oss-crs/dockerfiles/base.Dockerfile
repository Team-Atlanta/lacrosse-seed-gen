# Lacrosse Seedgen Base Image
# Contains the lacrosse_llm Python module for LLM-based seed generation

FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /crs

# Install Python dependencies needed by lacrosse_llm.find_inputs
# Traced from imports: openai (llm.py), langchain-core/openai/anthropic/community
# (utils.py, standard_args.py, monkeypatch_langchain.py), pydantic (patch_file_inputs.py)
RUN pip install --no-cache-dir \
    openai \
    langchain-core \
    langchain-openai \
    langchain-anthropic \
    langchain-community \
    pydantic

# Copy the langchain module (contains lacrosse_llm package)
COPY crs/code/langchain /crs/langchain
