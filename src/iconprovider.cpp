#include "iconprovider.h"

#include <QColor>
#include <QFile>
#include <QPainter>
#include <QSvgRenderer>

IconProvider::IconProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage IconProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    const int slash = id.indexOf(QLatin1Char('/'));
    const QString name = slash < 0 ? id : id.left(slash);
    QString color = slash < 0 ? QStringLiteral("000000") : id.mid(slash + 1);
    if (!color.startsWith(QLatin1Char('#')))
        color.prepend(QLatin1Char('#'));

    const QSize target = (requestedSize.width() > 0 && requestedSize.height() > 0) ? requestedSize : QSize(48, 48);
    if (size)
        *size = target;

    QImage img(target, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);

    QFile f(QStringLiteral(":/qt/qml/Exam1App/resources/icons/%1.svg").arg(name));
    if (!f.open(QIODevice::ReadOnly))
        return img;
    QByteArray svg = f.readAll();
    const QColor c(color);
    svg.replace("currentColor", c.name(QColor::HexRgb).toLatin1());
    QSvgRenderer renderer(svg);
    QPainter p(&img);
    p.setRenderHint(QPainter::Antialiasing);
    if (c.alpha() < 255)
        p.setOpacity(c.alphaF());
    renderer.render(&p);
    return img;
}
