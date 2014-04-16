#!/usr/bin/env python
# -*- coding: utf-8 -*-

import smtplib
import email.header
import email.mime.base
import email.mime.text
import email.mime.multipart


class NOTIFYError(Exception):
    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return self.msg


def send_mail(fromaddr, toaddr, subject, content, **kwargs):
    msg = email.mime.multipart.MIMEMultipart("alternative")
    msg.preamble = 'This is a multi-part message in MIME format.'

    if not (fromaddr and toaddr and subject and content):
        raise NOTIFYError("Mail w/o any of from, to, subject, content")

    if kwargs.get('From'):
        msg['From'] = kwargs.get('From')
    else:
        msg['From'] = fromaddr

    if kwargs.get('To'):
        msg['To'] = kwargs.get('To')
    else:
        msg['To'] = ','.join(toaddr)

    msg['Subject'] = str(email.header.Header(subject))

    priority = kwargs.get('priority')
    if priority and priority in (1, 2, 3, 4, 5):
        priorities = {
            1: "1 (Highest)",
            2: "2",
            3: "3 (Normal)",
            4: "4",
            5: "5 (Lowest)",
        }
        msg['X-Priority'] = priorities[priority]

    notify = kwargs.get('notification')
    if notify:
        msg['Disposition-Notification-To'] = notify

    msg.attach(email.mime.text.MIMEText(content, "plain", "utf-8"))

    if kwargs.get('use_ssl'):
        port = kwargs.get('port', 465)
        server = smtplib.SMTP_SSL(kwargs.get('host', 'localhost'), port)
    else:
        port = kwargs.get('port', 25)
        server = smtplib.SMTP(kwargs.get('host', 'localhost'), port)
    ehlo = kwargs.get('ehlo')
    if ehlo:
        server.ehlo(ehlo)
    user = kwargs.get('user')
    password = kwargs.get('password')
    if user and password:
        server.login(user, password)
    server.sendmail(fromaddr, toaddr, msg.as_string())
    server.quit()
