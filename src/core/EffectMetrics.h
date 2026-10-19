#pragma once
#include <QRectF>
#include <QVariantMap>
#include <QList>
#include <cmath>

namespace EffectMetrics {
// Geometry is in logical pixels: equal travel distances use equal playback times.
inline QVariantMap measure(const QList<QRectF> &regions,const QVariantMap &settings) {
    QRectF bounds;
    QList<QRectF> lines;
    double area=0;
    for(const auto &rect:regions) {
        if(rect.isEmpty()) continue;
        bounds=bounds.united(rect); area+=rect.width()*rect.height();
        bool found=false;
        for(auto &line:lines) {
            const double overlap=qMin(line.bottom(),rect.bottom())-qMax(line.top(),rect.top());
            if(overlap>qMin(line.height(),rect.height())*0.5) {line=line.united(rect);found=true;break;}
        }
        if(!found) lines.append(rect);
    }
    const double boost=settings.value("adaptive",true).toBool()?qMin(1.8,1+0.25*std::log2(qMax(1,int(lines.size())))):1;
    const double band=qMax(12.,bounds.width()*settings.value("shimmerWidth",40).toDouble()/100*boost);
    const double distance=bounds.width()+band;
    const bool adaptiveTime=settings.value("durationMode","fixed").toString()=="adaptive";
    const double duration=adaptiveTime
        ?settings.value("adaptiveBaseTime",600).toDouble()*distance/400*settings.value("adaptiveTimeScale",1).toDouble()
        :settings.value("duration",700).toDouble()/settings.value("speed",1).toDouble();
    return {{"lineCount",lines.size()},{"left",bounds.x()},{"span",bounds.width()},{"boost",boost},{"bandWidth",band},{"distance",distance},{"area",area},
        {"duration",settings.value("resolvedDuration",qMax(1.,duration))}};
}
}
