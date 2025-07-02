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
