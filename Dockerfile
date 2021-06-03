FROM gradle:jre14@sha256:98fb9d961a5406a1eab923e8097a3f91fa0d5fc1d04832e708b8994634e51410 as signal
WORKDIR /build
RUN git clone --depth 1 https://github.com/AsamK/signal-cli.git .
RUN ./gradlew build && ./gradlew installDist

FROM golang:alpine@sha256:0dc62c5cc2d97657c17ff3bc0224214e10226e245c94317e352ee8a2c54368b4 as receiver
WORKDIR /build
COPY . .
RUN go build

FROM openjdk:14-alpine@sha256:b8082268ef46d44ec70fd5a64c71d445492941813ba9d68049be6e63a0da542f
WORKDIR /app
COPY --from=signal /build/build/install/signal-cli/bin/ ./bin/
COPY --from=signal /build/build/install/signal-cli/lib/ ./lib/
COPY --from=receiver /build/alertmanager-signal-receiver ./bin/
RUN apk add --no-cache libgcc gcompat
RUN mkdir ./data && chown -R nobody:nogroup ./data
ENV PATH /app/bin:$PATH
USER nobody:nogroup
ENTRYPOINT ["alertmanager-signal-receiver"]
VOLUME /app/data
EXPOSE 9709/tcp

