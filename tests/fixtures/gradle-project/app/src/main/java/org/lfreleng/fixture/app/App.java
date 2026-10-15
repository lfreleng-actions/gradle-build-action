// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 The Linux Foundation

package org.lfreleng.fixture.app;

import org.lfreleng.fixture.core.Greeter;

/** Entry point that prints a greeting from the core module. */
public final class App {

    private App() {
    }

    /**
     * Returns the message the application prints.
     *
     * @return the message
     */
    public static String message() {
        return Greeter.greet("Gradle");
    }

    /**
     * Prints the message.
     *
     * @param args ignored
     */
    public static void main(final String[] args) {
        System.out.println(message());
    }
}
