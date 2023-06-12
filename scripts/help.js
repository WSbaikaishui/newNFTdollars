
const fs = require('fs');

function readAddressList () {
    return JSON.parse(fs.readFileSync('address.json', 'utf8'));
};

function storeAddressList(addressList) {
    fs.writeFileSync('address.json', JSON.stringify(addressList, null, '\t'));
};

module.exports = {
    readAddressList,
    storeAddressList
}