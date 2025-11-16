# nmap2report

nmap2report is a tool that generates security reports (in Markdown or PDF format) from Nmap XML output files. It parses Nmap scan results and produces a structured report of discovered hosts, open ports, services, and known vulnerabilities (with CVEs and CVSS scores), enriched with additional details like CWE categories and severity ratings. The tool can be used via a command-line interface or a simple graphical interface, and includes two report styles (simple and corporate) to cater to different reporting needs.

## Features

- **Nmap XML Parsing**: Safely parses Nmap `-oX` XML output to extract hosts, IP addresses, hostnames, open ports, service names/versions, and NSE script results.

- **Vulnerability Identification**: Integrates with Nmap's `vulners` NSE script output to identify CVEs and their CVSS scores on detected services.

- **CVE Enrichment**: Maps CVEs to CWE identifiers, severity levels, and recommendations using an internal JSON database (editable for customization).

- **Report Generation**: Produces well-formatted Markdown reports using Jinja2 templates. Two report styles are available:
  - **Simple**: A concise list-style report (host/port centric)
  - **Corporate**: A more detailed report with executive summary and structured findings

- **PDF Conversion**: Optionally converts the Markdown report to PDF if Pandoc is installed.

- **User Interface**: Provides both a CLI for automation and power-users, and a minimal GUI (built with PySimpleGUI) for ease of use.

- **Docker Support**: Includes a Dockerfile to run the tool in an isolated container environment (useful to avoid installing dependencies locally).

## Installation

### Prerequisites

- **Python 3.x** environment (if running locally)
- The tool uses the following Python libraries: `click`, `PySimpleGUI`, `Jinja2`, `defusedxml`. These will be installed as part of setup.
- For PDF output, ensure **Pandoc** is installed and available in your PATH (or use the provided Docker image which includes Pandoc).

### Install via Git (Local)

1. Clone this repository:
   ```bash
   git clone https://github.com/yourname/nmap2report.git
   cd nmap2report
   ```

2. (Optional) Create a Python virtual environment and activate it

3. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```
   (Alternatively, install directly via pip: `pip install click PySimpleGUI Jinja2 defusedxml`)

You're ready to run nmap2report using the CLI or launch the GUI.

### Running with Docker

If you prefer using Docker, build the Docker image and run the tool in a container:

1. Build the Docker image:
   ```bash
   docker build -t nmap2report .
   ```

2. Run the container, mounting any necessary volumes for input/output. For example:
   ```bash
   docker run --rm -v "$PWD/examples:/data" nmap2report -i /data/sample_scan.xml -o /data/report.md -s semplice
   ```

This command runs the tool on `examples/sample_scan.xml` (mapped into the container) and outputs `report.md` to the examples directory.

> **Note**: The Docker image's entrypoint is configured to run the CLI. You can pass CLI options directly to `docker run` as shown. If you want to use the GUI via Docker, additional steps (like setting up X11 forwarding) are required and are not covered here.

## Usage

### CLI Usage

After installation, you can use the nmap2report CLI. The basic syntax is:
```bash
python -m pentest_report_gen.cli [OPTIONS]
```

(If installed as a package or using Docker, you may run `nmap2report [OPTIONS]` directly.)

**Options:**
- `-i, --input TEXT`: Path to the Nmap XML file to parse (required)
- `-o, --output TEXT`: Path for the output report file. If not specified, a default name will be used (e.g., if input is scan.xml, output might be scan_report.md or .pdf)
- `-f, --format [md|pdf]`: Output format: md for Markdown (default) or pdf for PDF
- `-s, --style [semplice|corporate]`: Report style: semplice (simple) or corporate. Default is semplice
- `--gui`: Launch the GUI instead of running in CLI mode

**Examples:**

Generate a simple Markdown report from an Nmap XML:
```bash
nmap2report -i examples/sample_scan.xml -o report.md -f md -s semplice
```

Generate a corporate-style report and convert to PDF:
```bash
nmap2report -i examples/sample_scan.xml -o report.pdf -f pdf -s corporate
```

Launch the GUI:
```bash
nmap2report --gui
```

### GUI Usage

To use the graphical interface, run the tool with the `--gui` option (or launch the `show_gui()` function in Python). A window will appear.

**Using the GUI:**
- Select the Nmap XML file to import (click "Browse" to choose the file)
- Choose the Report style ("semplice" or "corporate") from the drop-down
- Choose the Output format (Markdown or PDF) from the drop-down
- Specify the Output file path (click "Save As" to choose location and name). You can leave this blank to use the default (the tool will then auto-name the report file based on the input file)
- Click "Genera report" to generate the report. A status message will appear at the bottom indicating success or any errors

The GUI will create the report file at the specified location. If PDF format is selected but pandoc is not installed (for local runs), an error message will be shown.

## Example Output

Below is a snippet of an example report (Markdown format, simple style) generated by nmap2report from an Nmap scan:

```markdown
# Report di scansione Nmap

## Host: 192.168.1.10 (testhost.local)
- **Porta 53/tcp** – domain (ISC BIND 9.10.3-P4)
    - **CVE-2012-1667** – CVSS: 8.5 (Alta) – CWE: CWE-189 – **Raccomandazione:** Aggiornare BIND all'ultima versione disponibile.
    - **CVE-2011-4313** – CVSS: 5.0 (Media) – CWE: CWE-399 – **Raccomandazione:** Applicare gli aggiornamenti di sicurezza rilasciati per BIND.
- **Porta 80/tcp** – http (Apache httpd 2.4.7)
    - Nessuna vulnerabilità nota rilevata su questo servizio.
```

The above corresponds to a scan of a single host with two open ports. In the report:
- Port 53/tcp (DNS) had two known vulnerabilities (listed with their CVE IDs, severity, etc.)
- Port 80/tcp had no known vulnerabilities

The Markdown can be viewed as-is or converted to PDF for distribution. For a complete example, see the file `examples/sample_report.md` in this repository.

## License

This project is released under the MIT License. Feel free to use and modify the tool according to your needs.

## Contributing

Contributions are welcome! If you have enhancements, bug fixes, or additional features (e.g., support for other NSE scripts or output formats), please open an issue or submit a pull request.
