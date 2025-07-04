const express = require('express');
const multer = require('multer');
const { S3Client } = require('@aws-sdk/client-s3');
const multerS3 = require('multer-s3');

// 1. Configura o Cliente S3 para usar as permissões do ambiente (IAM Role)
const s3Client = new S3Client({});

// 2. Configura o Multer para fazer o upload PRIVADO para o S3
const upload = multer({
    storage: multerS3({
        s3: s3Client,
        bucket: process.env.AWS_S3_BUCKET_NAME, // Lendo da variável de ambiente
        metadata: function (req, file, cb) {
            cb(null, { fieldName: file.fieldname });
        },
        key: function (req, file, cb) {
            const fileName = `repositorio/${Date.now().toString()}-${file.originalname}`;
            cb(null, fileName);
        }
    })
});

// 3. Inicializa a aplicação Express
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static('public'));

app.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).send('Nenhum arquivo foi enviado.');
    }
    console.log('Arquivo enviado com sucesso (privado):', req.file.key);
    // Retornamos a chave do objeto, já que a URL não será pública
    res.status(200).json({ 
        message: 'Arquivo enviado com sucesso!',
        fileKey: req.file.key 
    });
});

// 4. Inicia o servidor
app.listen(PORT, () => {
    console.log(`Servidor rodando e escutando na porta ${PORT}`);
});