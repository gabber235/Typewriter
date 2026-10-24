package main

import (
	"bytes"
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"testing"
	"time"
)

func TestBackendCommandsPreserveStatusAndDiagnostics(t *testing.T) {
	wrappers := []struct {
		name      string
		bootstrap bool
		command   func(*testing.T, string) []string
	}{
		{
			name: "command",
			command: func(t *testing.T, primary string) []string {
				return withBackendTargetCleanup(primary, "argument with spaces", "literal;$value")
			},
		},
		{
			name:      "component",
			bootstrap: true,
			command: func(t *testing.T, primary string) []string {
				command := backendTestCommand("argument with spaces", "literal;$value")
				if len(command) < 5 || command[4] != componentTestXtask {
					t.Fatalf("component command does not invoke the xtask: %q", command)
				}
				// Substitute only the container executable. The generated shell wrapper runs unchanged.
				command[4] = primary
				return command
			},
		},
	}
	for _, wrapper := range wrappers {
		t.Run(wrapper.name, func(t *testing.T) {
			type scenario struct {
				name          string
				buildStatus   int
				primaryStatus int
				cleanupStatus int
				wantStatus    int
			}
			cases := []scenario{
				{name: "success"},
				{name: "primary_failure", primaryStatus: 7, wantStatus: 7},
				{name: "cleanup_failure", cleanupStatus: 9, wantStatus: 9},
				{name: "primary_and_cleanup_failure", primaryStatus: 7, cleanupStatus: 9, wantStatus: 7},
			}
			if wrapper.bootstrap {
				cases = append(cases,
					scenario{name: "bootstrap_failure", buildStatus: 7, wantStatus: 7},
					scenario{name: "bootstrap_and_cleanup_failure", buildStatus: 7, cleanupStatus: 9, wantStatus: 7},
				)
			}
			for _, test := range cases {
				t.Run(test.name, func(t *testing.T) {
					result := probeBackendCommand(t, wrapper.command, test.buildStatus, test.primaryStatus, test.cleanupStatus)
					if result.status != test.wantStatus {
						t.Errorf("exit status = %d, want %d; stderr: %s", result.status, test.wantStatus, result.stderr)
					}

					wantTrace, wantStdout, wantStderr := "", "", ""
					if wrapper.bootstrap {
						wantTrace += "cargo: <build> <--locked> <--manifest-path> <backend/tests/component/Cargo.toml> <-p> <component-test-xtask>\n"
						wantStdout += "build output\n"
						wantStderr += "build diagnostics\n"
					}
					if test.buildStatus == 0 {
						wantTrace += "primary: <argument with spaces> <literal;$value>\n"
						wantStdout += "primary output\n"
						wantStderr += "primary diagnostics\n"
					}
					wantTrace += "cargo: <clean> <--manifest-path> </workspace/backend/Cargo.toml> <--target-dir> <target with spaces>\n"
					wantStderr += "cleanup diagnostics\n"
					if result.trace != wantTrace {
						t.Errorf("command trace = %q, want %q", result.trace, wantTrace)
					}
					if result.stdout != wantStdout {
						t.Errorf("stdout = %q, want %q", result.stdout, wantStdout)
					}
					if result.stderr != wantStderr {
						t.Errorf("stderr = %q, want %q", result.stderr, wantStderr)
					}
				})
			}
		})
	}
}

type backendCommandProbe struct {
	status int
	trace  string
	stdout string
	stderr string
}

func probeBackendCommand(t *testing.T, wrap func(*testing.T, string) []string, buildStatus, primaryStatus, cleanupStatus int) backendCommandProbe {
	t.Helper()
	directory := t.TempDir()
	trace := filepath.Join(directory, "trace")
	for name, script := range map[string]string{
		"cargo": `#!/bin/sh
{
    printf 'cargo:'
    printf ' <%s>' "$@"
    printf '\n'
} >> "$BACKEND_TEST_TRACE"
case "$1" in
    build)
        printf 'build output\n'
        printf 'build diagnostics\n' >&2
        exit "$BACKEND_TEST_BUILD_STATUS"
        ;;
    clean)
        printf 'cleanup output\n'
        printf 'cleanup diagnostics\n' >&2
        exit "$BACKEND_TEST_CLEANUP_STATUS"
        ;;
    *) exit 99 ;;
esac
`,
		"primary": `#!/bin/sh
{
    printf 'primary:'
    printf ' <%s>' "$@"
    printf '\n'
} >> "$BACKEND_TEST_TRACE"
printf 'primary output\n'
printf 'primary diagnostics\n' >&2
exit "$BACKEND_TEST_PRIMARY_STATUS"
`,
	} {
		if err := os.WriteFile(filepath.Join(directory, name), []byte(script), 0o700); err != nil {
			t.Fatal(err)
		}
	}
	arguments := wrap(t, filepath.Join(directory, "primary"))
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	command := exec.CommandContext(ctx, arguments[0], arguments[1:]...)
	command.Dir = directory
	command.Env = []string{
		"PATH=" + directory,
		"CARGO_TARGET_DIR=target with spaces",
		"BACKEND_TEST_TRACE=" + trace,
		"BACKEND_TEST_BUILD_STATUS=" + strconv.Itoa(buildStatus),
		"BACKEND_TEST_PRIMARY_STATUS=" + strconv.Itoa(primaryStatus),
		"BACKEND_TEST_CLEANUP_STATUS=" + strconv.Itoa(cleanupStatus),
	}
	var stdout, stderr bytes.Buffer
	command.Stdout, command.Stderr = &stdout, &stderr
	status := 0
	if err := command.Run(); err != nil {
		var exitError *exec.ExitError
		if !errors.As(err, &exitError) {
			t.Fatalf("run wrapper: %v", err)
		}
		status = exitError.ExitCode()
	}
	contents, err := os.ReadFile(trace)
	if err != nil {
		t.Fatal(err)
	}
	return backendCommandProbe{status: status, trace: string(contents), stdout: stdout.String(), stderr: stderr.String()}
}
