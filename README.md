# Projeto: Plataforma de Upload Automatizado para S3 com CI/CD

## 🎯 O Problema

O time de desenvolvimento precisava de uma forma rápida, padronizada e segura para enviar arquivos para um bucket S3 da AWS, sem a necessidade de acesso manual ao console da AWS ou de configurar credenciais em cada máquina. O processo anterior era manual, lento e suscetível a erros.

## 🚀 A Solução Implementada

Desenvolvi uma solução de automação completa (CI/CD) que permite que qualquer desenvolvedor envie arquivos para o S3 de forma segura através de uma interface web simples. A plataforma inteira é gerenciada como código e implantada automaticamente na AWS.

### 🛠️ Tecnologias Utilizadas

**Aplicação:** Node.js com Express.js

**Containerização:** Docker

**Infraestrutura como Código (IaC):** Terraform

**Automação (CI/CD):** GitHub Actions

**Cloud (AWS):**

**AWS S3:** Para armazenamento de objetos.

**AWS ECR (Elastic Container Registry):** Para armazenamento das imagens Docker.

**AWS App Runner:** Para execução do contêiner da aplicação de forma gerenciada e escalável.

**AWS IAM:** Para gerenciamento fino de permissões entre os serviços.

## 📐 Arquitetura da Solução
Descrição do Fluxo:
1. O desenvolvedor envia uma alteração de código para a branch 'main' no GitHub.
2. O GitHub Actions é acionado automaticamente.
3. A pipeline constrói a imagem Docker da aplicação Node.js.
4. A imagem é enviada para o repositório privado no Amazon ECR.
5. A pipeline comanda o AWS App Runner para iniciar um novo deploy usando a imagem mais recente do ECR.
6. O App Runner executa a aplicação, que por sua vez tem permissão via IAM Role para fazer uploads no bucket S3.

## 🧠 Desafios e Aprendizados

Um dos maiores desafios foi resolver o problema de dependência ("ovo e da galinha") entre a criação da infraestrutura no Terraform e a necessidade de uma imagem Docker no ECR para o App Runner. A solução foi um processo de bootstrapping em múltiplas etapas, criando primeiro os recursos base (ECR) e depois utilizando a pipeline para popular o ECR antes da criação final do serviço App Runner

```mermaid
graph LR
    subgraph "Ambiente de Desenvolvimento"
        A[👨‍💻 Engenheiro DevOps/Cloud]
        Tf[📄 Código Terraform]
    end

    subgraph "Plataforma de Versionamento e CI/CD"
        B[📦 Repositório GitHub]
        C[🤖 Pipeline GitHub Actions]
    end

    subgraph "Nuvem AWS (Região: us-east-1)"
        ECR[🪝 Amazon ECR]
        AppRunner[🚀 AWS App Runner]
        S3[🗄️ Bucket S3<br>welcome-ecopower]
        IAM[🔑 Roles e Permissões IAM]
        
        App[⚙️ Aplicação Node.js<br>em execução]
    end

    U[🧑‍💼 Usuário Final]

    %% Fluxos de Trabalho
    A -- "1. terraform apply" --> Tf
    Tf -- "Descreve e Cria" --> ECR
    Tf -- "Descreve e Cria" --> AppRunner
    Tf -- "Descreve e Cria" --> S3
    Tf -- "Descreve e Cria" --> IAM

    A -- "2. git push" --> B
    B -- "Aciona Pipeline" --> C
    C -- "Constrói e Envia Imagem" --> ECR
    C -- "Inicia Deploy" --> AppRunner

    AppRunner -- "Puxa Imagem" --> ECR
    AppRunner -- "Executa" --> App
    U -- "Acessa URL" --> AppRunner
    App -- "Usa permissões para upload" --> S3
    AppRunner -- "Utiliza papéis de" --> IAM
