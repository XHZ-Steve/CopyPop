#pragma once
#include <QObject>
#include <QPointF>
#include <algorithm>
#include <cmath>

// Time-based spring, shared by the native cursor toast and its interactive preview.
class MotionFollower : public QObject {
    Q_OBJECT
    Q_PROPERTY(QPointF position READ position NOTIFY changed)
    Q_PROPERTY(QPointF velocity READ velocity NOTIFY changed)
    Q_PROPERTY(QPointF target MEMBER target NOTIFY changed)
    Q_PROPERTY(double stiffness MEMBER stiffness)
    Q_PROPERTY(double damping MEMBER damping)
public:
    explicit MotionFollower(QObject *parent = nullptr) : QObject(parent) {}
    QPointF position() const { return m_position; }
    QPointF velocity() const { return m_velocity; }
    QPointF target;
    double stiffness = 700;
    double damping = 1;
    Q_INVOKABLE void reset(QPointF point) { m_position=target=point; m_velocity={}; emit changed(); }
    Q_INVOKABLE void advance(double seconds) {
        if (!std::isfinite(seconds) || seconds<=0) return;
        // Bound catch-up after a stall; fixed small substeps keep high stiffness stable at any Hz.
        const double duration=std::min(seconds,0.08);
        const int steps=std::max(1,int(std::ceil(duration*480)));
        const double dt=duration/steps;
        const double k=std::clamp(stiffness,80.0,2000.0);
        const double resistance=2*std::clamp(damping,0.4,2.0)*std::sqrt(k);
        for(int i=0;i<steps;++i) {
            m_velocity+=((target-m_position)*k-m_velocity*resistance)*dt;
            m_position+=m_velocity*dt;
        }
        if ((target-m_position).manhattanLength()<0.03 && m_velocity.manhattanLength()<0.1) { m_position=target; m_velocity={}; }
        emit changed();
    }
signals:
    void changed();
private:
    QPointF m_position,m_velocity;
};
