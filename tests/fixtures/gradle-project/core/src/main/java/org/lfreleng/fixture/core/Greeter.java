// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 The Linux Foundation

package org.lfreleng.fixture.core;

/** Builds the greeting the app module prints. */
public final class Greeter {

    private Greeter() {
    }

    /**
     * Returns a greeting for the given name.
     *
     * @param name the name to greet
     * @return the greeting
     */
    public static String greet(final String name) {
        return "Hello, " + name + "!";
    }
}
