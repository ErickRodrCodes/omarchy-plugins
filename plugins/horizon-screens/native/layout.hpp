#pragma once
#include <algorithm>
#include <cmath>
#include <span>

namespace HorizonLayout {
struct Output { double x, y, width, height, scale; int transform; bool explicitPosition; };
struct Origin { double x, y; };
inline Origin origin(std::span<const Output> outputs) {
    Origin result{outputs.front().x, outputs.front().y};
    for (const auto& m : outputs) {
        result.x = std::min(result.x, m.x);
        result.y = std::min(result.y, m.y);
    }
    return result;
}
// Use resolved compositor positions, including auto placement. X11 has a
// nonnegative root origin; translating all outputs equally preserves the layout.
inline bool supported(std::span<const Output> outputs) {
    if (outputs.empty()) return false;
    for (const auto& m : outputs) {
        if (m.scale != 1 || m.transform != 0 || m.width <= 0 || m.height <= 0) return false;
        for (double value : {m.x, m.y, m.width, m.height})
            if (!std::isfinite(value) || std::floor(value) != value) return false;
    }
    const auto base = origin(outputs);
    for (size_t i = 0; i < outputs.size(); ++i) {
        const auto& a = outputs[i];
        if (a.x-base.x+a.width > 32767 || a.y-base.y+a.height > 32767) return false;
        for (size_t j = i+1; j < outputs.size(); ++j) {
            const auto& b = outputs[j];
            if (a.x < b.x+b.width && b.x < a.x+a.width &&
                a.y < b.y+b.height && b.y < a.y+a.height) return false;
        }
    }
    return true;
}
}
