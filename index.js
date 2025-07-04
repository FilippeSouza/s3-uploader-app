const express = require('express');
const multer = require('multer');
const { S3Client } = require('@aws-sdk/client-s3');
const multerS3 = require('multer-s3');

// Configura o Cliente S3 para usar as permissões do ambiente (IAM Role do App Runner)
const s3Client = new S3Client({});

// Configura o Multer para fazer o upload com ACL pública
const upload = multer({
    storage: multerS3({
        s3: s3Client,
        bucket: process.env.AWS_S3_BUCKET_NAME,
        acl: 'public-read',
        key: function (req, file, cb) {
            const fileName = `global/${Date.now().toString()}-${file.originalname}`;
            cb(null, fileName);
        }
    })
});

const app = express();
// O App Runner nos informa a porta correta através da variável de ambiente PORT
const PORT = process.env.PORT || 3000;

app.use(express.static('public'));

app.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).send('Nenhum arquivo foi enviado.');
    }
    // Retorna a URL pública do arquivo
    res.status(200).json({ 
        message: 'Arquivo enviado com sucesso!',
        url: req.file.location 
    });
});

app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});