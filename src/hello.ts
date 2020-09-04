export class Message {
    message: string;

    constructor(messsage: string) {
        this.message = messsage;
    }
}

export function handlerHello(): Message {
    return new Message('Hello World !');
}
