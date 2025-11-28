FROM python:3.12-slim

# Install system dependencies (Pandoc for PDF export)
RUN apt-get update && \
    apt-get install -y --no-install-recommends pandoc && \
    rm -rf /var/lib/apt/lists/*

# Workdir inside the container
WORKDIR /app

# Copy the project into the image
COPY . /app

# Install Python dependencies directly (we run from source, not from wheel)
RUN pip install --no-cache-dir \
    click \
    jinja2 \
    defusedxml \
    pandas \
    pyarrow

# Use the CLI module as default entrypoint
ENTRYPOINT ["python", "-m", "pentest_report_gen.cli"]

# Default command (can be overridden at runtime)
CMD ["--help"]
