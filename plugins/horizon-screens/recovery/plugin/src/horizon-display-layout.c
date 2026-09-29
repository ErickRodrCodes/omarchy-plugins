#define _GNU_SOURCE

#include <X11/extensions/Xinerama.h>
#include <X11/extensions/Xrandr.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef XineramaScreenInfo *(*query_screens_fn)(Display *, int *);
typedef struct _GdkScreen GdkScreen;
typedef struct {
    int x;
    int y;
    int width;
    int height;
} GdkRectangle;
typedef void (*monitor_geometry_fn)(GdkScreen *, int, GdkRectangle *);
typedef XRRCrtcInfo *(*get_crtc_info_fn)(Display *, XRRScreenResources *, RRCrtc);

static int compare_screens(const void *left, const void *right);

static int parse_layout(XineramaScreenInfo *items, int capacity)
{
    const char *cursor = getenv("HORIZON_DISPLAY_LAYOUT");
    int count = 0;

    if (cursor == NULL)
        return 0;

    while (count < capacity && *cursor != '\0') {
        int old_x;
        int old_y;
        int old_width;
        int old_height;
        int x;
        int y;
        int width;
        int height;
        int consumed = 0;

        if (sscanf(cursor, "%d,%d,%d,%d,%d,%d,%d,%d%n",
                   &old_x, &old_y, &old_width, &old_height,
                   &x, &y, &width, &height, &consumed) != 8)
            break;
        (void)old_x;
        (void)old_y;
        (void)old_width;
        (void)old_height;
        items[count].screen_number = count;
        items[count].x_org = (short)x;
        items[count].y_org = (short)y;
        items[count].width = (short)width;
        items[count].height = (short)height;
        count++;
        cursor += consumed;
        if (*cursor == ';')
            cursor++;
        else if (*cursor != '\0')
            break;
    }

    qsort(items, (size_t)count, sizeof(*items), compare_screens);
    return count;
}

XRRCrtcInfo *XRRGetCrtcInfo(Display *display, XRRScreenResources *resources,
                            RRCrtc crtc)
{
    static get_crtc_info_fn real_get_crtc_info;
    XRRCrtcInfo *info;
    const char *cursor;

    if (real_get_crtc_info == NULL)
        real_get_crtc_info = (get_crtc_info_fn)dlsym(
            RTLD_NEXT, "XRRGetCrtcInfo");
    if (real_get_crtc_info == NULL)
        return NULL;

    info = real_get_crtc_info(display, resources, crtc);
    cursor = getenv("HORIZON_DISPLAY_LAYOUT");
    if (info == NULL || cursor == NULL)
        return info;

    while (*cursor != '\0') {
        int old_x;
        int old_y;
        int old_width;
        int old_height;
        int x;
        int y;
        int width;
        int height;
        int consumed = 0;

        if (sscanf(cursor, "%d,%d,%d,%d,%d,%d,%d,%d%n",
                   &old_x, &old_y, &old_width, &old_height,
                   &x, &y, &width, &height, &consumed) != 8)
            break;
        if (info->x == old_x && info->y == old_y &&
            info->width == (unsigned int)old_width &&
            info->height == (unsigned int)old_height) {
            info->x = x;
            info->y = y;
            info->width = (unsigned int)width;
            info->height = (unsigned int)height;
            break;
        }
        cursor += consumed;
        if (*cursor == ';')
            cursor++;
        else if (*cursor != '\0')
            break;
    }

    return info;
}

static int compare_screens(const void *left, const void *right)
{
    const XineramaScreenInfo *a = left;
    const XineramaScreenInfo *b = right;

    if (a->x_org != b->x_org)
        return (int)a->x_org - (int)b->x_org;
    return (int)a->y_org - (int)b->y_org;
}

XineramaScreenInfo *XineramaQueryScreens(Display *display, int *number)
{
    static query_screens_fn real_query;
    XineramaScreenInfo *screens;
    XineramaScreenInfo *corrected;
    int count;

    if (real_query == NULL) {
        real_query = (query_screens_fn)dlsym(RTLD_NEXT, "XineramaQueryScreens");
        if (real_query == NULL)
            return NULL;
    }

    screens = real_query(display, number);
    if (screens == NULL || number == NULL || *number <= 0)
        return screens;

    corrected = malloc((size_t)*number * sizeof(*corrected));
    if (corrected == NULL)
        return screens;
    count = parse_layout(corrected, *number);
    if (count == *number)
        memcpy(screens, corrected, (size_t)*number * sizeof(*screens));
    free(corrected);

    return screens;
}

void gdk_screen_get_monitor_geometry(GdkScreen *screen, int monitor,
                                     GdkRectangle *destination)
{
    static monitor_geometry_fn real_geometry;
    XineramaScreenInfo corrected[32];
    int count;

    if (real_geometry == NULL)
        real_geometry = (monitor_geometry_fn)dlsym(
            RTLD_NEXT, "gdk_screen_get_monitor_geometry");
    if (real_geometry == NULL)
        return;

    real_geometry(screen, monitor, destination);
    count = parse_layout(corrected, 32);
    if (destination == NULL || monitor < 0 || monitor >= count)
        return;

    destination->x = corrected[monitor].x_org;
    destination->y = corrected[monitor].y_org;
    destination->width = corrected[monitor].width;
    destination->height = corrected[monitor].height;
}
