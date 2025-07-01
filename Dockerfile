# Passo 1: Usar uma image base oficial do Node.js 
# Começamos com uma base pronta, uma versão leve e oficial do Node.js
FROM node:18-alpine

#Passo 2: Criar e definir o diretorio de trabalho dentro do container
# é como criar uma pasta c:\app dentro da nossa "caixa".
WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD [ "node", "index.js" ]