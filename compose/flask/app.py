from flask import Flask, request

app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Hello World12'


@app.route('/test')
def hello_test():
    return 'Hello Test'


@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        fs = request.files.getlist('files')  # 一次性多个文件
        print(fs)
    return "asd"


@app.route('/name/<name>')
def hello(name):
    # 保存数据库
    # age = 11
    # db.save(f"insert user(name,age) values(${name},${age}) ")

    return 'Hello' + name


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
