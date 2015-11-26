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

#include "audiorecorder.h"

#include <QDebug>
#include <QDir>
#include <QUrl>
#include <QTemporaryFile>

AudioRecorder::AudioRecorder(QObject *parent)
    : QObject(parent)
{
    m_audioRecorder = new QAudioRecorder();
    connect(m_audioRecorder, SIGNAL(stateChanged(QMediaRecorder::State)),
            SIGNAL(recorderStateChanged()));
    connect(m_audioRecorder, SIGNAL(statusChanged(QMediaRecorder::Status)),
            SIGNAL(recorderStatusChanged()));
    connect(m_audioRecorder, SIGNAL(error(QMediaRecorder::Error)),
            SLOT(updateRecorderError(QMediaRecorder::Error)));
    connect(m_audioRecorder, SIGNAL(actualLocationChanged(QUrl)),
            SLOT(updateActualLocation(QUrl)));
    connect(m_audioRecorder, SIGNAL(durationChanged(qint64)), SIGNAL(durationChanged(qint64)));
    connect(m_audioRecorder, SIGNAL(audioInputChanged(const QString&)),
            SIGNAL(audioInputChanged(const QString&)));

    m_audioSettings = m_audioRecorder->audioSettings();
}

AudioRecorder::~AudioRecorder()
{
    delete m_audioRecorder;
}

AudioRecorder::RecorderState AudioRecorder::recorderState() const
{
    return RecorderState(m_audioRecorder->state());
}

AudioRecorder::RecorderStatus AudioRecorder::recorderStatus() const
{
    return RecorderStatus(m_audioRecorder->status());
}

AudioRecorder::Error AudioRecorder::errorCode() const
{
    return Error(m_audioRecorder->error());
}

QString AudioRecorder::errorString() const
{
    return m_audioRecorder->errorString();
}

QString AudioRecorder::outputLocation() const
{
    return m_audioRecorder->outputLocation().toString();
}

QString AudioRecorder::actualLocation() const
{
    return m_audioRecorder->actualLocation().toString();
}

qint64 AudioRecorder::duration() const
{
    return m_audioRecorder->duration();
}

int AudioRecorder::bitRate() const
{
    return m_audioSettings.bitRate();
}

int AudioRecorder::channelCount() const
{
    return m_audioSettings.channelCount();
}

QString AudioRecorder::codec() const
{
    return m_audioSettings.codec();
}

AudioRecorder::EncodingQuality AudioRecorder::quality() const
{
    return EncodingQuality(m_audioSettings.quality());
}

int AudioRecorder::sampleRate() const
{
    return m_audioSettings.sampleRate();
}

QString AudioRecorder::audioInput() const
{
    return m_audioRecorder->audioInput();
}

void AudioRecorder::record()
{
    setRecorderState(RecordingState);
}

void AudioRecorder::stop()
{
    setRecorderState(StoppedState);
}

void AudioRecorder::pause()
{
    setRecorderState(PausedState);
}

void AudioRecorder::setRecorderState(AudioRecorder::RecorderState state)
{
    if (!m_audioRecorder)
        return;

    switch (state){
        case AudioRecorder::RecordingState: {
            // Create temporary file to store audio recorded
            QTemporaryFile outputFile(QDir::temp().absoluteFilePath("audioXXXXXX%1").arg(m_fileExtension));
            outputFile.setAutoRemove(false);
            outputFile.open();
            outputFile.close();
            setOutputLocation(outputFile.fileName());

            m_audioRecorder->record();
            break;
        }
        case AudioRecorder::StoppedState:
            m_audioRecorder->stop();
            break;
        case AudioRecorder::PausedState:
            m_audioRecorder->pause();
            break;
    }
}

void AudioRecorder::setOutputLocation(const QString &location)
{
    if (outputLocation() != location) {
        // FIXME: implement auto-removal of previous recordings
        m_audioRecorder->setOutputLocation(location);
        Q_EMIT outputLocationChanged(outputLocation());
    }
}

void AudioRecorder::setBitRate(int rate)
{
    if (bitRate() != rate) {
        m_audioSettings.setBitRate(rate);
        Q_EMIT bitRateChanged(rate);
    }
}

void AudioRecorder::setChannelCount(int count)
{
    if (channelCount() != count) {
        m_audioSettings.setChannelCount(count);
        Q_EMIT channelCountChanged(count);
    }
}

void AudioRecorder::setCodec(const QString &audioCodec)
{
    if (codec() != audioCodec) {
        if (!m_audioRecorder->supportedAudioCodecs().contains(audioCodec)) {
            qWarning() << "AudioRecorder error: Unsupported Audio Codec: " << audioCodec;
            return;
        }

        if (audioCodec == "audio/vorbis" ||
            audioCodec == "audio/speex" ||
            audioCodec == "audio/FLAC") {

            m_audioRecorder->setContainerFormat("ogg");
            m_fileExtension = ".ogg";
        } else if (audioCodec == "audio/PCM") {
            m_audioRecorder->setContainerFormat("wav");
            m_fileExtension = ".wav";
        } else {
            m_audioRecorder->setContainerFormat("raw");
        }

        m_audioSettings.setCodec(audioCodec);
        Q_EMIT codecChanged(audioCodec);
    }
}

void AudioRecorder::setQuality(AudioRecorder::EncodingQuality encodingQuality)
{
    if (quality() != encodingQuality) {
        m_audioSettings.setQuality(QMultimedia::EncodingQuality(encodingQuality));
        Q_EMIT qualityChanged(encodingQuality);
    }
}

void AudioRecorder::setSampleRate(int rate)
{
    if (sampleRate() != rate) {
        m_audioSettings.setSampleRate(rate);
        Q_EMIT sampleRateChanged(rate);
    }
}

void AudioRecorder::setAudioInput(const QString &input)
{
    if (audioInput() != input) {
        m_audioRecorder->setAudioInput(input);
        Q_EMIT audioInputChanged(input);
    }
}

void AudioRecorder::updateRecorderError(QMediaRecorder::Error errorCode)
{
    qWarning() << "AudioRecorder error:" << errorString();
    Q_EMIT errorChanged(Error(errorCode), errorString());
}

void AudioRecorder::updateActualLocation(const QUrl &url)
{
    Q_EMIT actualLocationChanged(url.toString());
}
