# Windows App Certification Kit action

[![Test](https://github.com/ChristopheLav/wack-certification/actions/workflows/test.yml/badge.svg)](https://github.com/ChristopheLav/wack-certification/actions/workflows/test.yml)

This action allows to run the Windows App Certification Kit (WACK) and generate test results (certification report + Check Run).

![Example of WACK check run](imgs/wack-check-run-example.png)

## Requirements

- A Windows runner

## What's new

Refer [here](CHANGELOG.md) to the changelog.

## Inputs

| Input | Required | Example | Default Value | Description |
|-|-|-|-|-|
| `name`          | Yes | 'WACK (x64)'  | | Name of the WACK execution (used for the GitHub Check Run) |
| `package-path`          | Yes | '/release/DemoApp.msixbundle'  | | Relative path of the target package to test with the WACK (appxbundle or msixbundle) |
| `report-name`          | Yes | 'DemoApp.Certification.xml'  | | Desired name of the certification report |
| `ignore-rules`          | No | '38,81,83'  | | List of WACK rules to ignore separated by a comma |
| `threat-as-warning-rules`          | No | '38,81'  | | List of WACK rules to thread as warning if failed separated by a comma |

The available rules of the Windows App Certification Kit (WACK) are documented [here](https://learn.microsoft.com/en-us/windows/uwp/debug-test-perf/windows-app-certification-kit-tests).

## Outputs

| Output | Example | Description |
|-|-|-|
| `report-path`          | '/wack-certification/DemoApp.Certification.xml'  | Path of the certification report |

## Usage

<!-- start usage -->
```yaml
- uses: ChristopheLav/wack-certification@v1
  with:
    name: 'WACK (x64)'
    package-path: '/release/DemoApp.msixbundle'
    report-name: 'DemoApp.Certification.xml'
    ignore-rules: '38,81'
    threat-as-warning-rules: '83'
```
<!-- end usage -->

Also, you need to ensure your workflow has the permission `checks:write`.

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)