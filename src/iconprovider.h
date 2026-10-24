// "image://icon/<name>/<rrggbb>" : renders a bundled SVG icon in the requested colour.
#pragma once

#include <QQuickImageProvider>

class IconProvider : public QQuickImageProvider
{
public:
    IconProvider();
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};
