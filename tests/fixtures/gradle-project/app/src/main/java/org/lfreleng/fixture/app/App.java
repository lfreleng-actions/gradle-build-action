// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 The Linux Foundation

package org.lfreleng.fixture.app;

import org.lfreleng.fixture.core.Greeter;

/** Prints a greeting built by the core module. */
public final class App {
    private App() {
    }

    /**
     * Returns the message this application prints.
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
    public static void main(String[] args) {
        System.out.println(message());
    }
}
