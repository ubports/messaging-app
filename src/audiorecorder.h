/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * Authors:
 *  Arthur Renato Mello <arthur.mello@canonical.com>
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef AUDIORECORDER_H
#define AUDIORECORDER_H

#include <QObject>
#include <QAudioRecorder>

class AudioRecorder : public QObject
{
    Q_OBJECT

    Q_ENUMS(EncodingQuality)
    Q_ENUMS(Error)
    Q_ENUMS(RecorderState)
    Q_ENUMS(RecorderStatus)

    Q_PROPERTY(RecorderState recorderState READ recorderState WRITE setRecorderState NOTIFY recorderStateChanged)
    Q_PROPERTY(RecorderStatus recorderStatus READ recorderStatus NOTIFY recorderStatusChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorChanged)
    Q_PROPERTY(Error errorCode READ errorCode NOTIFY errorChanged)
    Q_PROPERTY(QString outputLocation READ outputLocation NOTIFY outputLocationChanged)
    Q_PROPERTY(QString actualLocation READ actualLocation NOTIFY actualLocationChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(int bitRate READ bitRate WRITE setBitRate NOTIFY bitRateChanged);
    Q_PROPERTY(int channelCount READ channelCount WRITE setChannelCount NOTIFY channelCountChanged);
    Q_PROPERTY(QString codec READ codec WRITE setCodec NOTIFY codecChanged);
    Q_PROPERTY(EncodingQuality quality READ quality WRITE setQuality NOTIFY qualityChanged);
    Q_PROPERTY(int sampleRate READ sampleRate WRITE setSampleRate NOTIFY sampleRateChanged);
    Q_PROPERTY(QString audioInput READ audioInput WRITE setAudioInput NOTIFY audioInputChanged);

public:
    enum EncodingQuality
    {
        VeryLowQuality = QMultimedia::VeryLowQuality,
        LowQuality = QMultimedia::LowQuality,
        NormalQuality = QMultimedia::NormalQuality,
        HighQuality = QMultimedia::HighQuality,
        VeryHighQuality = QMultimedia::VeryHighQuality
    };

    enum Error
    {
        NoError = QMediaRecorder::NoError,
        ResourceError = QMediaRecorder::ResourceError,
        FormatError = QMediaRecorder::FormatError,
        OutOfSpaceError = QMediaRecorder::OutOfSpaceError
    };
 
    enum RecorderState
    {
        StoppedState = QMediaRecorder::StoppedState,
        RecordingState = QMediaRecorder::RecordingState,
        PausedState = QMediaRecorder::PausedState
    };

    enum RecorderStatus
    {
        UnavailableStatus = QMediaRecorder::UnavailableStatus,
        UnloadedStatus = QMediaRecorder::UnloadedStatus,
        LoadingStatus = QMediaRecorder::LoadingStatus,
        LoadedStatus = QMediaRecorder::LoadedStatus,
        StartingStatus = QMediaRecorder::StartingStatus,
        RecordingStatus = QMediaRecorder::RecordingStatus,
        PausedStatus = QMediaRecorder::PausedStatus,
        FinalizingStatus = QMediaRecorder::FinalizingStatus
    };

    AudioRecorder(QObject *parent = 0);
    ~AudioRecorder();

    RecorderState recorderState() const;
    RecorderStatus recorderStatus() const;
    Error errorCode() const;
    QString errorString() const;
    QString outputLocation() const;
    QString actualLocation() const;
    qint64 duration() const;
    int bitRate() const;
    int channelCount() const;
    QString codec() const;
    EncodingQuality quality() const;
    int sampleRate() const;
    QString audioInput() const;

public Q_SLOTS:
    void record();
    void stop();
    void pause();
    void setRecorderState(AudioRecorder::RecorderState state);
    void setOutputLocation(const QString &location);
    void setBitRate(int rate);
    void setChannelCount(int count);
    void setCodec(const QString &audioCodec);
    void setQuality(AudioRecorder::EncodingQuality encodingQuality);
    void setSampleRate(int rate);
    void setAudioInput(const QString &input);

Q_SIGNALS:
    void recorderStateChanged();
    void recorderStatusChanged();
    void errorChanged(AudioRecorder::Error errorCode, const QString &errorString);
    void outputLocationChanged(const QString &location);
    void actualLocationChanged(const QString &location);
    void durationChanged(qint64 duration);
    void bitRateChanged(int rate);
    void channelCountChanged(int count);
    void codecChanged(const QString &codec);
    void qualityChanged(AudioRecorder::EncodingQuality quality);
    void sampleRateChanged(int rate);
    void audioInputChanged(const QString &input);

private Q_SLOTS:
    void updateRecorderError(QMediaRecorder::Error);
    void updateActualLocation(const QUrl&);

private:
    QAudioRecorder *m_audioRecorder;
    QAudioEncoderSettings m_audioSettings;
    QString m_fileExtension;
};

#endif // AUDIORECORDER_H
