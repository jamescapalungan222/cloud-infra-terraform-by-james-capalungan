resource "aws_instance" "ubuntu" {
    ami = "ami-0b8d527345fdace59"
    instance_type = "t3.small"

    tags = {
        Name = "UbuntuServer"
    }
}

resource "aws_instance" "proxy" {
    ami = "ami-0b8d527345fdace59"
    instance_type = "t3.small"

    tags = {
        Name = "ProxyServer"
    }
}