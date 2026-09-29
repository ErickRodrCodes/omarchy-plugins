#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/state/MonitorPositionController.hpp>
#include <hyprland/src/state/MonitorLayoutController.hpp>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include "layout.hpp"

namespace {
CFunctionHook* hook = nullptr;
using Outputs = std::span<const SP<Monitor::IMonitorArrangeable>>;
using Arrange = void (*)(const State::CMonitorPositionController*, Outputs, bool);

void arrange(const State::CMonitorPositionController* self, Outputs outputs, bool zeroScaling) {
    // Preserve Hyprland's complete logical-layout algorithm and scale handling.
    reinterpret_cast<Arrange>(hook->m_original)(self, outputs, zeroScaling);
    std::vector<HorizonLayout::Output> row;
    row.reserve(outputs.size());
    for (const auto& m : outputs) {
        const auto p = m->position(), size = m->size();
        row.push_back({p.x, p.y, size.x, size.y, m->scale(),
                       static_cast<int>(m->transform()), m->explicitPosition().has_value()});
    }
    if (!HorizonLayout::supported(row)) return;
    // This runs BEFORE MonitorLayoutController publishes XDG output geometry.
    // Output identity/order and Wayland positions are untouched; X11 positions
    // now agree with them, so pointer and window translations share one space.
    const auto base = HorizonLayout::origin(row);
    for (const auto& m : outputs) m->setXWaylandPosition(m->position() - Vector2D{base.x, base.y});
}

bool horizonRunning() {
    for (const auto& entry : std::filesystem::directory_iterator("/proc")) {
        const auto name = entry.path().filename().string();
        if (name.empty() || name.find_first_not_of("0123456789") != std::string::npos) continue;
        std::ifstream file(entry.path() / "comm");
        std::string comm;
        std::getline(file, comm);
        if (comm != "horizon-client" && comm != "horizon-protoco" && comm != "horizon-protocol") continue;
        const char* instance = std::getenv("HYPRLAND_INSTANCE_SIGNATURE");
        std::ifstream environment(entry.path() / "environ", std::ios::binary);
        if (!instance || !environment) return true; // unknown ownership: refuse
        std::string item;
        bool identified = false;
        while (std::getline(environment, item, '\0')) {
            if (!item.starts_with("HYPRLAND_INSTANCE_SIGNATURE=")) continue;
            identified = true;
            if (item.substr(std::string("HYPRLAND_INSTANCE_SIGNATURE=").size()) == instance) return true;
        }
        if (!identified) return true;
    }
    return false;
}
}

APICALL EXPORT std::string PLUGIN_API_VERSION() { return HYPRLAND_API_VERSION; }
APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    if (std::string(__hyprland_api_get_hash()) != __hyprland_api_get_client_hash())
        throw std::runtime_error("Horizon input layout: rebuild against this Hyprland version");
    if (horizonRunning()) throw std::runtime_error("Fully quit Horizon before enabling input layout");
    const auto matches = HyprlandAPI::findFunctionsByName(handle, "arrange");
    void* target = nullptr;
    for (const auto& match : matches) {
        if (!match.demangled.starts_with("State::CMonitorPositionController::arrange(")) continue;
        if (target) throw std::runtime_error("Ambiguous monitor arrangement API");
        target = match.address;
    }
    if (!target) throw std::runtime_error("Unsupported Hyprland monitor arrangement API");
    hook = HyprlandAPI::createFunctionHook(handle, target, reinterpret_cast<void*>(&arrange));
    if (!hook || !hook->hook()) throw std::runtime_error("Cannot hook monitor arrangement");
    State::monitorLayoutController()->arrange();
    return {"horizon-input-layout", "Match XWayland display and input coordinates to Hyprland", "Erick Rodriguez", "0.2.0"};
}
APICALL EXPORT void PLUGIN_EXIT() {
    if (hook) hook->unhook();
    // Restore stock X11 geometry through the same publication path on unload.
    State::monitorLayoutController()->arrange();
}
