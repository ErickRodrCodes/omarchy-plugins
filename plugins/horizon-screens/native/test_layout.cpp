#include "layout.hpp"
#include <cassert>
#include <limits>
#include <vector>
using HorizonLayout::Output;
int main() {
    std::vector<std::vector<Output>> layouts{
        {{4864,0,1920,1080,1,0,true},{0,0,3840,2160,1,0,true},{3840,0,1024,600,1,0,true}},
        {{-1920,400,1920,1080,1,0,false},{0,-1080,1920,1080,1,0,true}},
        {{100,200,800,600,1,0,false}},
        {{0,0,800,600,1,0,true},{900,0,800,600,1,0,true},{0,700,800,600,1,0,true},{900,700,800,600,1,0,true}},
    };
    for (auto row : layouts) {
        assert(HorizonLayout::supported(row));
        auto base = HorizonLayout::origin(row);
        for (const auto& m : row)
            for (double dx : {0.0,m.width-1}) for (double dy : {0.0,m.height-1}) {
                const double x = m.x-base.x+dx, y = m.y-base.y+dy;
                assert(x >= 0 && y >= 0 && x < 32767 && y < 32767);
                assert(x+base.x == m.x+dx && y+base.y == m.y+dy);
            }
        std::reverse(row.begin(), row.end());
        assert(HorizonLayout::supported(row));
        assert(HorizonLayout::origin(row).x == base.x);
        assert(HorizonLayout::origin(row).y == base.y);
    }
    assert(!HorizonLayout::supported({}));
    auto row = layouts.front();
    for (int kind=0; kind<6; ++kind) {
        auto bad=row;
        switch(kind) {
            case 0: bad[0].scale=2; break;
            case 1: bad[0].transform=1; break;
            case 2: bad[0].x=3840; break;
            case 3: bad[0].width=0; break;
            case 4: bad[0].y=std::numeric_limits<double>::quiet_NaN(); break;
            case 5: bad[0].x=32767; break;
        }
        assert(!HorizonLayout::supported(bad));
    }
}
