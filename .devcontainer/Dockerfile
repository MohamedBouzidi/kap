FROM ubuntu:jammy

ARG KIND_IP

RUN apt update -y && apt install -y vim curl tmux sudo zsh git jq tar \
  apt-transport-https ca-certificates software-properties-common gnupg2 \
  language-pack-en gettext-base dnsutils unzip mkisofs iproute2
RUN useradd -ms /usr/bin/zsh user && \
echo 'user:user' | chpasswd && \
usermod -aG sudo user && \
apt update -y && apt install -y make

USER user
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN sed -i -e 's/ZSH_THEME=.*/ZSH_THEME="eastwood"/g' ~/.zshrc
RUN echo "export DOCKER_HOST=tcp://${KIND_IP}:2375" >> ~/.zshrc

RUN git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
RUN sh ~/.vim_runtime/install_awesome_vimrc.sh

USER root
RUN curl -L https://go.dev/dl/go1.19.4.linux-arm64.tar.gz -o /tmp/go.tar.gz && \
tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz

RUN apt-get update -y && apt-get install gnupg lsb-release
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
apt-get update -y && apt-get install -y docker-ce-cli

RUN curl -L "https://releases.hashicorp.com/terraform/1.3.7/terraform_1.3.7_linux_arm64.zip" -o "terraform.zip" && \
unzip terraform.zip && rm terraform.zip && chmod +x terraform && mv terraform /usr/local/bin

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && \
chmod +x kubectl && mv kubectl /usr/local/bin

RUN curl -L "https://get.helm.sh/helm-v3.11.3-linux-arm64.tar.gz" -o helm.tar.gz && tar xvzf helm.tar.gz && \
chmod +x linux-arm64/helm && mv linux-arm64/helm /usr/local/bin/helm && rm -rf linux-arm64/ helm.tar.gz

RUN curl -L "https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx_v0.9.4_linux_x86_64.tar.gz" -o /tmp/kubectx.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/kubectx.tar.gz && rm /tmp/kubectx.tar.gz && \
chmod +x /usr/local/bin/kubectx

RUN curl -L "https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens_v0.9.4_linux_x86_64.tar.gz" -o /tmp/kubens.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/kubens.tar.gz && rm /tmp/kubens.tar.gz && \
chmod +x /usr/local/bin/kubens

RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64 && \
chmod +x kind && mv kind /usr/local/bin

RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-arm64 && \
chmod +x skaffold && mv skaffold /usr/local/bin/

RUN curl -L https://github.com/istio/istio/releases/download/1.17.1/istio-1.17.1-linux-arm64.tar.gz  -o /tmp/istio.tar.gz && \
tar -C /home/user -xzf /tmp/istio.tar.gz && rm /tmp/istio.tar.gz && chown -R user:user /home/user/istio-1.17.1

USER user
RUN sed -i -e 's/plugins=(/plugins=(kube-ps1 /g' ~/.zshrc
RUN echo 'PROMPT=\$\(kube_ps1\)$PROMPT' >> ~/.zshrc
RUN echo 'export PATH=$PATH:/usr/local/go/bin:/home/user/istio-1.17.1/bin' >> ~/.zshrc
RUN echo "source <(kubectl completion zsh)" >> ~/.zshrc

