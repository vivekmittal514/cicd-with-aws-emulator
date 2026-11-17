FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal

RUN ARCH="$(uname -m)" && \
    curl -fsSL "https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest/aws-emulator-${ARCH}.rpm" \
      -o /tmp/aws-emulator.rpm && \
    rpm -i /tmp/aws-emulator.rpm && \
    rm /tmp/aws-emulator.rpm && \
    mkdir -p /home/emulator && chown 1000 /home/emulator

USER 1000
ENV HOME=/home/emulator
EXPOSE 9297
ENTRYPOINT ["aws-emulator", "-b", "0.0.0.0"]
