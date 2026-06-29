# Copyright (c) 2023, ARM Limited and Contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# Neither the name of ARM nor the names of its contributors may be used
# to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

FROM docker-harbor-pull.cixtech.com/cix-buildenv/cix-base:20260519-01
USER root
# RUN chmod -R 777 /etc/passwd /etc/group /etc/sudoers && \
#     echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
#     chmod 440 /etc/sudoers
ARG UID
ARG GID
ARG CUSTOMER
RUN echo "uid: ${UID}, gid: ${GID}, user: ${CUSTOMER}"
ENV USER=${CUSTOMER}
RUN if ! getent group ${GID} >/dev/null; then \
        groupadd -g ${GID} ${CUSTOMER} || true; \
    else \
        echo "Group with GID ${GID} already exists, using existing group"; \
        existing_group=$(getent group ${GID} | cut -d: -f1); \
        if [ "${existing_group}" != "${CUSTOMER}" ]; then \
            groupmod -n ${CUSTOMER} ${existing_group} || true; \
        fi; \
    fi && \
    useradd -l -u ${UID} -g ${GID} -m -s /bin/bash ${CUSTOMER} || true && \
    usermod -aG sudo ${CUSTOMER} || true && \
    echo "${CUSTOMER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user && \
    chmod 440 /etc/sudoers.d/user

# COPY entrypoint.sh /entrypoint.sh
# RUN chmod 555 /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]

USER ${CUSTOMER}
