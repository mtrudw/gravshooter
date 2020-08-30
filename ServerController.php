// <?php
// namespace App\Controller;

// use FOS\RestBundle\Controller\Annotations as Rest;
// //use FOS\RestBundle\Controller\FOSRestController;
// use App\Entity\Server;
// use Doctrine\ORM\EntityManagerInterface;

// class ServerController extends FOSRestController {

//      /**
//      * CreateServer resource
//      * @Rest\Post("/servers")
//      * @param Request $request
//      * @return View
//      */
//     public function postServer(Request $request): View
//     {
//         $entityManager = $this->getDoctrine()->getManager();
//         $server = new Server();
//         $server->setName($request->get('name'));
//         $server->setPlayercount(1);
//         $server->setCreated(new \DateTime("now"));
//         $server->setLastPing(new \DateTime("now"));
//         $server->setIp($_SERVER['REMOTE_ADDR']);
//         $entityManager->persist($server);
//         $entityManager->flush();
//         // In case our POST was a success we need to return a 201 HTTP CREATED response
//         return View::create($server, Response::HTTP_CREATED);
//     }
// }
// ?>
