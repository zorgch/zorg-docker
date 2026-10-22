module.exports = {
    // Startup message
    connection_message: ({hostname, version, os, type, architecture, cpu, memory}) =>
        `[<b>${hostname}</b>] Connected to docker v${version} Host:\n${type}/${architecture} [${os}] | ${cpu} CPU | RAM ${memory}`,

    // Container up
    container_start: e =>
        `🚀 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> (re)starting`,//\n` +
        //(e.Actor.Attributes['telegram-notifier.service-uri'] ? `<pre>${e.Actor.Attributes['telegram-notifier.service-uri']}</pre>` : ''),

    // Container down
    container_die: e => {
        const exitCode = e.Actor.Attributes.exitCode;
        const normalMap = {
            "0": "Initiated graceful Shutdown [exit <code>0</code>]",
            "130": "User terminated Container [exit <code>130</code>]",
            //"134": "Abnormal termination (SIGABRT): Exit code <code>134</code>", // Usually a process detects a critical error
            "137": "Down-ed or OOM killed Container (SIGKILL) [exit <code>137</code>]",
            "143": "Stopped Container (SIGTERM) [exit <code>143</code>]",
            // Add more normal exit codes as needed
        };
        const nonNormalMap = {
            "1": "Application quit (exit <code>1</code>)", // Something is rather "wrong" than just "stopped"
            //"2": "exit <code>2</code> - Misuse of shell builtins", // This is often a Container Crash
            "126": "exit <code>126</code> - Command invoked cannot execute",
            "127": "exit <code>127</code> - File or directory not found",
            "128": "exit <code>128</code> - Invalid argument used on exit",
            "139": "exit <code>139</code> - Segmentation fault",
            //"255": "exit <code>255</code> - Unknown error",
            // Add more non-normal exit codes as needed
        }

        if (exitCode in normalMap) {
            return `⏹️ <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> was STOPPED\n` +
            `${normalMap[exitCode]}`;
        } else if (exitCode in nonNormalMap) {
            return `🚨 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> is DOWN!\n` +
            `${nonNormalMap[exitCode]}`;
        } else {
            return `💥 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> CRASHED!\n` +
            `[exit <code>${exitCode}</code>]`;
        }
    },

    // Healthchecks
    'container_health_status: healthy': e =>
        `🟢 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> is ONLINE\n` +
        (e.Actor.Attributes['telegram-notifier.service-uri'] ? `<pre>${e.Actor.Attributes['telegram-notifier.service-uri']}</pre>` : ''),

    'container_health_status: unhealthy': e =>
        `🛟 <b>${e.Actor.Attributes['com.docker.compose.service']}(${e.Actor.Attributes['com.docker.compose.project']})</b> became UNHEALTHY!\n` +
        `Check <a href="https://${e.Actor.Attributes['com.docker.compose.project']}-dashboard">Docker Status Dashboard</a> for insights.`,
};
