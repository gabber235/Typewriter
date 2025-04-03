#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Navigate to the project root. Pulumi commands often need project context,
# and the .env file needs to be created in the root.
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"

echo "Attempting to generate .env file using Pulumi..."

# --- Run the Pulumi command with error handling ---
# Use a temporary file to avoid overwriting .env with partial output on failure.
PULUMI_OUTPUT_FILE=".pulumi_env_output.tmp"

if pulumi env open seamlezz/development/typewriter --format dotenv > "$PULUMI_OUTPUT_FILE"; then
    # Pulumi succeeded, commit the changes to .env.
    mv "$PULUMI_OUTPUT_FILE" .env
    echo ".env file generated/updated successfully."
else
    # Pulumi failed.
    PULUMI_EXIT_CODE=$?
    echo "" >&2
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
    echo "ERROR: Failed to generate .env file using Pulumi." >&2
    echo "Pulumi command exited with status code: $PULUMI_EXIT_CODE" >&2
    echo "" >&2
    echo "Troubleshooting tips:" >&2
    echo "  - Ensure you are logged into the Pulumi CLI ('pulumi login')." >&2
    echo "  - Verify the stack 'seamlezz/development/typewriter' exists and you have access." >&2
    echo "  - Check Pulumi project configuration and cloud provider credentials." >&2
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
    echo "" >&2

    rm -f "$PULUMI_OUTPUT_FILE"

    # Propagate the failure code from Pulumi.
    exit $PULUMI_EXIT_CODE
fi
# --- End of Pulumi command section ---


echo ""
echo "Setup complete. Run 'docker compose up' to start services."

exit 0
