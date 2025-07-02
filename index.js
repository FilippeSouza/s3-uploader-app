// 1. Importar os pacotes necessários
console.log("--- ESTOU EXECUTANDO A VERSÃO MAIS RECENTE DO ARQUIVO ---");
//require('dotenv').config(); // Carrega as variáveis do arquivo .env
const express = require('express');
const multer = require('multer');
const { S3Client } = require('@aws-sdk/client-s3');
const multerS3 = require('multer-s3');

// 2. Configurar o Cliente S3 da AWS
// O SDK vai automaticamente procurar as credenciais no seu ambiente ou no arquivo .env
const s3Client = new S3Client({
    region: process.env.AWS_REGION
});

// 3. Configurar o Multer para fazer o upload para o S3
const upload = multer({
    storage: multerS3({
        s3: s3Client,
        bucket: process.env.AWS_S3_BUCKET_NAME,
        acl: 'public-read', // Controle de Acesso: torna o arquivo publicamente legível
        metadata: function (req, file, cb) {
            // Adiciona metadados ao arquivo se necessário
            cb(null, { fieldName: file.fieldname });
        },
        key: function (req, file, cb) {
            // Define o nome do arquivo no S3
            // "envios_linux/" é o prefixo (a "pasta")
            // A sintaxe abaixo garante um nome único para evitar sobreposições
            const fileName = `envios_linux/${Date.now().toString()}-${file.originalname}`;
            cb(null, fileName);
        }
    })
});

// 4. Inicializar a aplicação Express
const app = express();
const PORT = 3000;

// Servir arquivos estáticos da pasta 'public' (onde nosso index.html está)
// Esta linha é responsável por mostrar a página de upload quando você acessa o site.
app.use(express.static('public'));

// 5. Definir a rota de upload
// O 'single('file')' corresponde ao nome do campo no nosso formulário HTML
app.post('/upload', upload.single('file'), (req, res) => {
    // Se o upload falhar ou nenhum arquivo for enviado, req.file não existirá
    if (!req.file) {
        return res.status(400).send('Nenhum arquivo foi enviado.');
    }

    console.log('Arquivo enviado com sucesso:', req.file);

    // O multer-s3 nos dá a URL pública do objeto no campo 'location'
    const fileUrl = req.file.location;

    // Retorna uma resposta JSON com a mensagem de sucesso e a URL do arquivo
    res.status(200).json({ 
        message: 'Arquivo enviado com sucesso!',
        url: fileUrl 
    });
});

// 6. Iniciar o servidor
app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
    console.log(`Acesse http://localhost:${PORT} para fazer o upload.`);
});