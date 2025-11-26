# nmap2report

**nmap2report** is a Python tool that generates security reports (Markdown or PDF) from Nmap XML output files.  
It parses Nmap scan results and produces structured reports of discovered hosts, open ports, services and known vulnerabilities (CVEs with CVSS scores), enriched with additional metadata such as CWE categories, severity ratings and per-host risk metrics.

The tool can be used from the command line or via a modern graphical interface, and includes two report styles (`simple` and `corporate`) to fit different reporting needs (quick triage vs. customer-facing deliverables).

---

## Features

- **Safe Nmap XML parsing**
  - Parses Nmap `-oX` XML output using `defusedxml` for safety.
  - Extracts hosts, IP addresses, hostnames, open ports, services (name, product, version, extrainfo) and NSE script output.
  - Supports multiple input XML files and merges results into a single consolidated report.

- **Vulnerability identification**
  - Detects CVEs and CVSS scores from NSE script output (e.g. `vulners`).
  - Handles both regex-based extraction from script text and structured data from `<table><elem key="id">`, `<elem key="cvss">`, etc.

- **CVE enrichment**
  - Uses an internal JSON mapping (`data/cve_cwe_map.json`) to enrich each CVE with:
    - CWE identifier
    - CVSS score (override/normalization)
    - Normalized severity (Critical/High/Medium/Low)
    - Human-readable remediation recommendation
  - The JSON file is editable and can be extended with your own mappings.

- **Risk analytics**
  - Computes per-host risk metrics:
    - `max_cvss`, `avg_cvss`
    - `risk_level` (Critical / High / Medium / Low / None)
  - Builds an aggregated **“Findings by CVE”** view showing all affected hosts/ports for each CVE.
  - Provides **Top Findings** in the corporate report:
    - Top risky hosts
    - Top critical CVE findings
    - Overall severity distribution.

- **Report generation**
  - Generates well-formatted Markdown reports using Jinja2 templates.
  - Two report styles:
    - **simple** – concise, host/port-centric list.
    - **corporate** – executive summary, Top Findings, grouped CVE view and detailed findings per host.
  - Optional PDF export via Pandoc.

- **(Planned) Docker support**
  - A Dockerfile is included as a starting point, but container support is currently considered **experimental / WIP**.

---

## Project structure

```text
nmap2report/
├─ data/
│  └─ cve_cwe_map.json        # CVE -> CWE/CVSS/severity/recommendation mapping
├─ examples/
│  ├─ sample_scan.xml
│  ├─ sample_scan_advanced.xml
│  └─ ...                     # example reports / generated sample reports
├─ pentest_report_gen/
│  ├─ cli.py                  # CLI entrypoint
│  ├─ gui.py                  # CustomTkinter GUI
│  ├─ parser.py               # Nmap XML parser and multi-file merge
│  └─ report.py               # Reporting engine and template rendering
├─ templates/
│  ├─ simple.md.j2            # "simple" report template
│  └─ corporate.md.j2         # "corporate" report template
├─ README.md
├─ requirements.txt
└─ LICENSE
````

---

## Installation

### Prerequisites

* **Python 3.9+** recommended.
* Python libraries (installed via `requirements.txt`):

  * `click`
  * `customtkinter`
  * `Jinja2`
  * `defusedxml`
* For PDF output:

  * **Pandoc** must be installed and available on your `PATH`.

### Local installation

Clone the repository:

```bash
git clone https://github.com/vitalelele/nmap2report.git
cd nmap2report
```

(Optionally) create and activate a virtual environment, then install dependencies:

```bash
pip install -r requirements.txt
```

You are now ready to use both the CLI and the GUI.

---

## CLI usage

The CLI entrypoint is `pentest_report_gen.cli`. From the project root:

```bash
python -m pentest_report_gen.cli [OPTIONS]
```

### Options

* `-i, --input PATH` (repeatable, **required**)
  Path to one or more Nmap XML files (`-oX` output). You can pass multiple `-i` options and they will be merged into a single report.

* `-o, --output PATH`
  Path to the output report file. If omitted, a default name is generated, e.g.:

  * `scan_simple_report.md`
  * `nmap_merged_corporate_report.pdf`

* `-f, --format [md|pdf]`
  Output format:

  * `md` (default) – Markdown
  * `pdf` – PDF (requires Pandoc)

* `-s, --style [simple|corporate]`
  Report style:

  * `simple` – compact list-style report
  * `corporate` – executive summary, Top Findings, grouping by CVE, host risk index

* `--customer TEXT`
  Customer name to appear in the corporate report header (optional).

* `--tester TEXT`
  Name of the security tester (optional).

* `--engagement TEXT`
  Engagement / project identifier (optional).

* `--scope TEXT`
  Scope description (IP ranges, assets, etc.) (optional).

* `--lang [en|it]` *(reserved for future i18n)*
  Currently used only as metadata in the report context.

* `-v, --verbose` (repeatable)
  Increase verbosity: `-v` = INFO, `-vv` = DEBUG.

### Examples

Generate a simple Markdown report from a single XML:

```bash
python -m pentest_report_gen.cli \
  -i examples/sample_scan.xml \
  -s simple \
  -f md
```

Generate a corporate PDF report from a single XML:

```bash
python -m pentest_report_gen.cli \
  -i examples/sample_scan_advanced.xml \
  -s corporate \
  -f pdf \
  --customer "ACME Corp." \
  --tester "Antonio Vitale" \
  --engagement "Internal Pentest Q4" \
  --scope "192.168.1.0/24" \
  -v
```

Merge multiple XML scans into a single corporate report:

```bash
python -m pentest_report_gen.cli \
  -i examples/sample_scan.xml \
  -i examples/sample_scan_advanced.xml \
  -s corporate \
  -f md \
  -vv
```

---

## GUI usage

The graphical interface is implemented in `pentest_report_gen.gui` using CustomTkinter.

Launch it from the project root:

```bash
python -m pentest_report_gen.gui
```
---

## CVE mapping file (`cve_cwe_map.json`)

The file `data/cve_cwe_map.json` acts as a small offline database used to enrich vulnerabilities discovered by Nmap.

Each entry typically looks like:

```json
{
  "CVE-2017-0143": {
    "CWE": "CWE-119",
    "CVSS": 10.0,
    "severity": "Critical",
    "recommendation": "Apply the MS17-010 security update and disable SMBv1 where possible."
  }
}
```

* **CWE**: CWE identifier of the underlying weakness.
* **CVSS**: Numeric score (v2/v3). If present, it can override the score parsed from Nmap.
* **severity**: Normalized label (`Critical`, `High`, `Medium`, `Low`).
* **recommendation**: Short remediation guidance displayed in the report.

You can freely extend or modify this mapping to cover more CVEs or to adapt severity and recommendations to your environment.

If a CVE is **not** present in the mapping, the tool falls back to:

* CVSS score from Nmap, if available, to derive severity.
* No CWE / recommendation.

---

## (Experimental) Docker usage

> ⚠️ **Docker support is currently experimental and may require adjustments.**
> The section below is kept as a reference for future configuration.

Build the image:

```bash
docker build -t nmap2report .
```

Run the container, mounting a local directory for input/output:

```bash
docker run --rm \
  -v "$PWD/examples:/data" \
  nmap2report \
  -i /data/sample_scan.xml \
  -o /data/report.md \
  -s simple \
  -f md
```

This runs the CLI inside the container against `examples/sample_scan.xml` and writes `report.md` back into the `examples` directory on the host.

> Note: the Docker image is primarily intended for CLI usage. Running the GUI through Docker would require additional configuration (X11/Wayland or similar) and is not covered here.

---

## Example output (corporate report snippet)

```markdown
# Security Report – Nmap Scan

## Executive Summary

- Total hosts analyzed: 2
- Active hosts: 2
- Total vulnerabilities identified: 3
- Severity distribution:
  Critical: 1 | Medium: 2

### Top Risk Hosts
- 192.168.1.20 – Max CVSS: 10.0 (Critical)
- 192.168.1.10 – Max CVSS: 5.0 (Medium)

### Top Critical Findings
- CVE-2017-0143 – Severity: Critical – CVSS: 10.0

---

## Findings by CVE (Grouped View)

### CVE-2017-0143
- Severity: Critical
- CVSS: 10.0
- Recommendation: Apply the MS17-010 security update and disable SMBv1 where possible.

Affected Hosts/Ports:
- 192.168.1.20 – Port 445/tcp (microsoft-ds)

---
```

---

## License

This project is released under the MIT License.
You are free to use, modify and distribute it under the terms of that license.

---

## Contributing

Contributions are welcome!

If you have ideas for improvements (new report styles, better templates, new CVE mappings, Docker improvements, etc.):

1. Open an issue to discuss the change, or
2. Fork the repository and submit a pull request.

Please try to keep code and templates in **English**, and include example XML / reports when adding new parsing features.
