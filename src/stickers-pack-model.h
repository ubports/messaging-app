#ifndef STICKERSPACKMODEL_H
#define STICKERSPACKMODEL_H

#include <QObject>
#include <QAbstractListModel>


class StickerPack
{
public:
    StickerPack(const QString &name, const QString &path, int count, const QString &thumbnail);

    QString name() const;
    QString path() const;
    int count() const;
    void setCount(int count) ;
    QString thumbnail() const;
    void setThumbnail(QString thumbnail);

private:
    QString m_name;
    QString m_path;
    int m_count;
    QString m_thumbnail;
};

class StickersPackModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString stickerPath READ stickerPath WRITE setStickerPath NOTIFY stickerPathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

public:
    explicit StickersPackModel(QObject *parent = nullptr);

    enum StickersPackRoles {
            StickerPackNameRole = Qt::UserRole + 1,
            StickerPackCountRole,
            StickerPackThumbnailRole,
            StickerPackPathRole,
        };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString stickerPath() const;
    void setStickerPath(const QString& path);

    Q_INVOKABLE void removePack(const QString& packName);
    Q_INVOKABLE void addSticker(const QString& packName, const QString& stickerPath);
    Q_INVOKABLE void removeSticker(const QString& packName, const QString& stickerPath);
    Q_INVOKABLE void createPack();
    Q_INVOKABLE QVariantMap get(int index) const;



Q_SIGNALS:
    void stickerPathChanged() const;
    void rowCountChanged();
    void packCreated(const QString packName);
    void packRemoved(const QString packName);


private:
    QString m_stickerPath;
    StickerPack generatePack();
    QList<StickerPack> m_stickerPacks;
    void populate();
    int getEntryIndex(const QString& packName);

};

#endif // STICKERSPACKMODEL_H
