// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 The Linux Foundation

package org.lfreleng.fixture.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class AppTest {
    @Test
    void messageUsesCoreGreeter() {
        assertEquals("Hello, Gradle!", App.message());
    }

    @Test
    void recordsTestJvm() throws IOException {
        String target = System.getProperty("fixture.jvmFile");
        assertNotNull(target, "fixture.jvmFile system property is not set");
        Path file = Path.of(target);
        Files.createDirectories(file.getParent());
        Files.writeString(file,
                System.getProperty("java.specification.version") + "\n",
                StandardCharsets.UTF_8);
    }
}
