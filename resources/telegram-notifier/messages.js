module.exports = {
    // Startup message
    connection_message: ({hostname, version, os, type, architecture, cpu, memory}) =>
        `[<b>${hostname}</b>] Connected to docker v${version} Host:\n${type}/${architecture} [${os}] | ${cpu} CPU | RAM ${memory}`,

    // Container up
    container_start: e =>
        `✅ <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> is UP!\n` +
        (e.Actor.Attributes['telegram-notifier.service-uri'] ? `<pre>${e.Actor.Attributes['telegram-notifier.service-uri']}</pre>` : ''),

    // Container down
    container_die: e => {
        const exitCode = e.Actor.Attributes.exitCode;
        const normalMap = {
            "0": "Successful shutdown: Exit code <code>0</code>",
            "1": "Application quit: Exit code <code>1</code>",
            "130": "Container terminated by user: Exit code <code>130</code>",
            "134": "Abnormal termination (SIGABRT): Exit code <code>134</code>",
            "137": "Immediate termination (SIGKILL): Exit code <code>137</code>",
            "143": "Graceful termination (SIGTERM): Exit code <code>143</code>",
            // Add more normal exit codes as needed
        };
        const nonNormalMap = {
            "2": "Exit code <code>2</code> - Misuse of shell builtins",
            "126": "Exit code <code>126</code> - Command invoked cannot execute",
            "127": "Exit code <code>127</code> - File or directory not found",
            "128": "Exit code <code>128</code> - Invalid argument used on exit",
            "139": "Exit code <code>139</code> - Segmentation fault",
            //"255": "Exit code <code>255</code> - Unknown error",
            // Add more non-normal exit codes as needed
        }

        if (exitCode in normalMap) {
            return `⏹️ <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> was STOPPED\n` +
            `[${normalMap[exitCode]}]`;
        } else if (exitCode in nonNormalMap) {
            return `🚨 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> is DOWN!\n` +
            `[${nonNormalMap[exitCode]}]`;
        } else {
            return `💥 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> has CRASHED!`;
        }
    },

    // Healthchecks
    'container_health_status: healthy': e =>
        `🔆 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> is healthy`,
    'container_health_status: unhealthy': e =>
        `🛟 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> became UNHEALTHY!\n` +
        `Check <a href="https://dockerstatus.zorg-local.dev">Docker Status Dashboard</a> for insights.`,
};
