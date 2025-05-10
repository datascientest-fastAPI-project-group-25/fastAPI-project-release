# Monitoring and Logging for Release Repository

This directory contains monitoring and logging configurations specific to the release process.

## Overview

The monitoring and logging setup for the release repository is designed to:

1. Track the release process
2. Monitor deployment status
3. Collect logs from release-related activities
4. Integrate with the main application's monitoring stack

## Integration with Application Monitoring

The release monitoring integrates with the main application monitoring stack located in the `fastAPI-project-app` repository. This ensures a unified view of the entire system, from development to deployment.

## Usage

### Setting Up Monitoring for Releases

To set up monitoring for releases:

```bash
# From the release repository root
cd scripts
npm run setup-monitoring
```

### Viewing Release Logs

Release logs can be viewed in the Grafana dashboard at:
- http://localhost:3001/d/releases/release-monitoring

## Configuration

The monitoring configuration is designed to be platform-independent and works across Windows, macOS, and Linux environments.

## Troubleshooting

If you encounter issues with the release monitoring:

1. Check that the main application monitoring stack is running
2. Verify that the release scripts are properly configured
3. Check the logs in the `logs` directory

## Contributing

When adding new monitoring or logging features:

1. Ensure they are platform-independent
2. Add appropriate documentation
3. Update the README.md file
