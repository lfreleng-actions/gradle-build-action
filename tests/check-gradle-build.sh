#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Verify a build of tests/fixtures/gradle-project ran on the expected
# Gradle release and JDK.
#
# Usage: bash tests/check-gradle-build.sh <project-dir> <gradle-version> <java>
#
#   project-dir     the fixture directory the build ran in
#   gradle-version  exact Gradle release, for example 9.8.1
#   java            Java feature version, for example 21
#
# When ACTION_GRADLE_VERSION, ACTION_JAVA_VERSION and
# ACTION_JAVA_DISTRIBUTION are set (the gradle-build-action outputs),
# they are checked too. Run the build first: the script reads the
# outputs it left under build/.
#
# Exit codes: 0 every check passed, 1 a check failed, 2 bad usage.

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <project-dir> <gradle-version> <java-version>" >&2
  exit 2
fi

project_dir="$1"
want_gradle="$2"
want_java="$3"

if [ ! -d "$project_dir" ]; then
  echo "Error: project directory not found: $project_dir" >&2
  exit 2
fi

errors=0
pass() { echo "OK: $*"; }
fail() { echo "Error: $*"; errors=$((errors + 1)); }

# True when a full Java version string belongs to the wanted feature
# version: '21', '21.0.5' and '21+35' match 21; '2' and '211' do not.
java_matches() {
  case "$1" in
    "$want_java" | "$want_java".* | "$want_java"+*) return 0 ;;
    *) return 1 ;;
  esac
}

# Action outputs
if [ -n "${ACTION_GRADLE_VERSION+set}" ] \
  || [ -n "${ACTION_JAVA_VERSION+set}" ] \
  || [ -n "${ACTION_JAVA_DISTRIBUTION+set}" ]; then
  if [ "${ACTION_GRADLE_VERSION:-}" = "$want_gradle" ]; then
    pass "action output gradle-version=$ACTION_GRADLE_VERSION"
  else
    fail "action output gradle-version: want '$want_gradle'," \
      "got '${ACTION_GRADLE_VERSION:-}'"
  fi
  if java_matches "${ACTION_JAVA_VERSION:-}"; then
    pass "action output java-version=$ACTION_JAVA_VERSION"
  else
    fail "action output java-version: want $want_java," \
      "got '${ACTION_JAVA_VERSION:-}'"
  fi
  if [ "${ACTION_JAVA_DISTRIBUTION:-}" = "temurin" ]; then
    pass "action output java-distribution=$ACTION_JAVA_DISTRIBUTION"
  else
    fail "action output java-distribution: want 'temurin'," \
      "got '${ACTION_JAVA_DISTRIBUTION:-}'"
  fi
fi

# Toolchain on PATH
if version_output=$(cd "$project_dir" && gradle --version 2>&1); then
  if printf '%s\n' "$version_output" | grep -qxF "Gradle $want_gradle"; then
    pass "gradle --version reports Gradle $want_gradle"
  else
    fail "gradle --version does not report Gradle $want_gradle"
    printf '%s\n' "$version_output"
  fi
  launcher=$(printf '%s\n' "$version_output" \
    | sed -n 's/^Launcher JVM:[[:space:]]*\([^[:space:]]*\).*/\1/p')
  if [ -n "$launcher" ] && java_matches "$launcher"; then
    pass "gradle --version reports Launcher JVM $launcher"
  else
    fail "gradle --version Launcher JVM: want $want_java, got '$launcher'"
  fi
else
  fail "gradle --version failed"
  printf '%s\n' "$version_output"
fi

# The JVM that ran the tests, as recorded by the fixture's own test
jvm_file="$project_dir/app/build/test-jvm/java-specification-version.txt"
if [ -f "$jvm_file" ]; then
  test_jvm=$(tr -d '[:space:]' < "$jvm_file")
  if [ "$test_jvm" = "$want_java" ]; then
    pass "tests ran on Java $test_jvm"
  else
    fail "tests ran on Java '$test_jvm', want $want_java"
  fi
else
  fail "test JVM record not found: $jvm_file"
fi

# Build outputs
for module in core app; do
  shopt -s nullglob
  jars=("$project_dir/$module/build/libs/"*.jar)
  shopt -u nullglob
  if [ "${#jars[@]}" -gt 0 ]; then
    pass "$module jar: ${jars[*]}"
  else
    fail "no jar under $project_dir/$module/build/libs"
  fi
done

# Test reports: at least one test, no failures or errors
shopt -s nullglob
reports=("$project_dir"/app/build/test-results/test/TEST-*.xml)
shopt -u nullglob
if [ "${#reports[@]}" -eq 0 ]; then
  fail "no JUnit XML reports under $project_dir/app/build/test-results"
else
  tests=0
  bad=0
  for report in "${reports[@]}"; do
    suite=$(grep -m1 '<testsuite ' "$report" || true)
    for attr in tests failures errors; do
      value=$(printf '%s' "$suite" \
        | sed -n "s/.* $attr=\"\([0-9]*\)\".*/\1/p")
      if [ -z "$value" ]; then
        fail "$report: no '$attr' count"
        value=0
      fi
      case "$attr" in
        tests) tests=$((tests + value)) ;;
        *) bad=$((bad + value)) ;;
      esac
    done
  done
  if [ "$tests" -gt 0 ] && [ "$bad" -eq 0 ]; then
    pass "$tests tests passed"
  else
    fail "test reports show $tests tests and $bad failures or errors"
  fi
fi

if [ "$errors" -ne 0 ]; then
  echo "$errors check(s) failed"
  exit 1
fi
echo "All checks passed"
